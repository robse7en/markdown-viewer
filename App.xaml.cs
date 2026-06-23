using System.Windows;

namespace MarkdownViewer;

/// <summary>
/// Application entry point. Captures an optional file path passed on the command
/// line (used by the .md file association) and hands it to the main window.
/// </summary>
public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        string? initialFile = e.Args.Length > 0 ? e.Args[0] : null;
        var window = new MainWindow(initialFile);
        window.Show();
    }
}
