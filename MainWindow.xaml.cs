using System.IO;
using System.Windows;
using Microsoft.Web.WebView2.Core;
using MarkdownViewer.Services;

namespace MarkdownViewer;

/// <summary>
/// Main application window. Hosts a WebView2 that displays the rendered Markdown,
/// plus a thin toolbar (Open + theme toggle). Resources are served to the WebView
/// through virtual host mappings so everything works offline and relative image
/// links inside the document resolve correctly.
/// </summary>
public partial class MainWindow : Window
{
    private const string AssetsHost = "appassets.local";   // bundled css/js
    private const string RenderHost = "appfiles.local";     // generated preview.html
    private const string DocHost = "mddoc.local";          // folder of the open .md file

    private readonly string _assetsDir;
    private readonly string _renderDir;
    private readonly string _previewPath;
    private readonly AppSettings _settings;

    private string? _currentFile;
    private string _currentDocDir = string.Empty;
    private bool _webViewReady;

    /// <summary>highlight.js stylesheet name matching the current theme.</summary>
    private string HljsStyle => _settings.Theme == "dark" ? "github-dark" : "github";

    public MainWindow(string? initialFile)
    {
        InitializeComponent();

        _assetsDir = Path.Combine(AppContext.BaseDirectory, "Assets");

        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string appDataDir = Path.Combine(localAppData, "MarkdownViewer");
        _renderDir = Path.Combine(appDataDir, "render");
        Directory.CreateDirectory(_renderDir);
        _previewPath = Path.Combine(_renderDir, "preview.html");

        _settings = AppSettings.Load();
        UpdateThemeButton();

        _currentFile = initialFile;
        Loaded += OnLoaded;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string userDataFolder = Path.Combine(localAppData, "MarkdownViewer", "WebView2");
        Directory.CreateDirectory(userDataFolder);

        var env = await CoreWebView2Environment.CreateAsync(null, userDataFolder);
        await WebView.EnsureCoreWebView2Async(env);

        var core = WebView.CoreWebView2;
        core.SetVirtualHostNameToFolderMapping(
            AssetsHost, _assetsDir, CoreWebView2HostResourceAccessKind.Allow);
        core.SetVirtualHostNameToFolderMapping(
            RenderHost, _renderDir, CoreWebView2HostResourceAccessKind.Allow);

        // Lock down: disable context menu noise but keep it usable; open external links in browser.
        core.Settings.AreDefaultContextMenusEnabled = true;
        core.NewWindowRequested += OnNewWindowRequested;

        _webViewReady = true;

        if (!string.IsNullOrWhiteSpace(_currentFile) && File.Exists(_currentFile))
        {
            LoadFile(_currentFile!);
        }
        else
        {
            ShowWelcome();
        }
    }

    private void OnNewWindowRequested(object? sender, CoreWebView2NewWindowRequestedEventArgs e)
    {
        // Open target=_blank / external links in the user's default browser, not a popup WebView.
        e.Handled = true;
        try
        {
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = e.Uri,
                UseShellExecute = true,
            });
        }
        catch
        {
            // Ignore links that can't be launched.
        }
    }

    private void LoadFile(string path)
    {
        try
        {
            string markdown = File.ReadAllText(path);
            string title = Path.GetFileName(path);
            string bodyHtml = MarkdownRenderer.ToHtml(markdown);

            string template = File.ReadAllText(Path.Combine(_assetsDir, "template.html"));
            string page = template
                .Replace("{{THEME}}", _settings.Theme)
                .Replace("{{HLJS}}", HljsStyle)
                .Replace("{{TITLE}}", System.Net.WebUtility.HtmlEncode(title))
                .Replace("{{ASSETS}}", $"https://{AssetsHost}")
                .Replace("{{BASE}}", $"https://{DocHost}/")
                .Replace("{{BODY}}", bodyHtml);

            File.WriteAllText(_previewPath, page);

            // Map the document's own folder so relative images resolve via the base href.
            string docDir = Path.GetDirectoryName(Path.GetFullPath(path)) ?? AppContext.BaseDirectory;
            RemapDocFolder(docDir);

            _currentFile = path;
            FileNameText.Text = path;
            Title = $"{title} — Markdown Viewer";

            // Cache-bust so re-navigation after a theme toggle always reloads.
            string url = $"https://{RenderHost}/preview.html?v={DateTime.Now.Ticks}";
            WebView.CoreWebView2.Navigate(url);
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, $"Could not open file:\n{path}\n\n{ex.Message}",
                "Markdown Viewer", MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private void RemapDocFolder(string docDir)
    {
        if (!string.IsNullOrEmpty(_currentDocDir))
        {
            try { WebView.CoreWebView2.ClearVirtualHostNameToFolderMapping(DocHost); }
            catch { /* not mapped yet */ }
        }

        WebView.CoreWebView2.SetVirtualHostNameToFolderMapping(
            DocHost, docDir, CoreWebView2HostResourceAccessKind.Allow);
        _currentDocDir = docDir;
    }

    private void ShowWelcome()
    {
        const string welcomeMd =
            "# Markdown Viewer\n\n" +
            "No file is open yet.\n\n" +
            "- Click **Open…** to choose a `.md` file\n" +
            "- Or **drag and drop** a Markdown file onto this window\n" +
            "- Or double-click a `.md` file in Explorer once the file association is installed\n";

        string title = "Welcome";
        string bodyHtml = MarkdownRenderer.ToHtml(welcomeMd);
        string template = File.ReadAllText(Path.Combine(_assetsDir, "template.html"));
        string page = template
            .Replace("{{THEME}}", _settings.Theme)
            .Replace("{{HLJS}}", HljsStyle)
            .Replace("{{TITLE}}", title)
            .Replace("{{ASSETS}}", $"https://{AssetsHost}")
            .Replace("{{BASE}}", $"https://{AssetsHost}/")
            .Replace("{{BODY}}", bodyHtml);
        File.WriteAllText(_previewPath, page);
        WebView.CoreWebView2.Navigate($"https://{RenderHost}/preview.html?v={DateTime.Now.Ticks}");
    }

    private void OnOpenClick(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "Markdown files (*.md;*.markdown)|*.md;*.markdown|All files (*.*)|*.*",
            Title = "Open Markdown file",
        };

        if (dialog.ShowDialog(this) == true)
        {
            LoadFile(dialog.FileName);
        }
    }

    private void OnThemeToggleClick(object sender, RoutedEventArgs e)
    {
        _settings.Theme = _settings.Theme == "dark" ? "light" : "dark";
        _settings.Save();
        UpdateThemeButton();

        if (!_webViewReady) return;

        if (!string.IsNullOrWhiteSpace(_currentFile) && File.Exists(_currentFile))
        {
            LoadFile(_currentFile!);
        }
        else
        {
            ShowWelcome();
        }
    }

    private void UpdateThemeButton()
    {
        ThemeButton.Content = _settings.Theme == "dark" ? "Light mode" : "Dark mode";
    }

    private void OnWindowDragOver(object sender, DragEventArgs e)
    {
        e.Effects = e.Data.GetDataPresent(DataFormats.FileDrop)
            ? DragDropEffects.Copy
            : DragDropEffects.None;
        e.Handled = true;
    }

    private void OnWindowDrop(object sender, DragEventArgs e)
    {
        if (!_webViewReady) return;
        if (e.Data.GetData(DataFormats.FileDrop) is string[] files && files.Length > 0)
        {
            LoadFile(files[0]);
        }
    }
}
