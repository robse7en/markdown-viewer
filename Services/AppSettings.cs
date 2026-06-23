using System.IO;
using System.Text.Json;

namespace MarkdownViewer.Services;

/// <summary>
/// Small persisted settings store (currently just the chosen theme), kept as a
/// JSON file under %APPDATA%\MarkdownViewer so the machine stays clean.
/// </summary>
public class AppSettings
{
    /// <summary>"light" or "dark".</summary>
    public string Theme { get; set; } = "light";

    private static string SettingsPath
    {
        get
        {
            string dir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "MarkdownViewer");
            Directory.CreateDirectory(dir);
            return Path.Combine(dir, "settings.json");
        }
    }

    public static AppSettings Load()
    {
        try
        {
            if (File.Exists(SettingsPath))
            {
                string json = File.ReadAllText(SettingsPath);
                var loaded = JsonSerializer.Deserialize<AppSettings>(json);
                if (loaded != null)
                {
                    if (loaded.Theme != "dark") loaded.Theme = "light";
                    return loaded;
                }
            }
        }
        catch
        {
            // Fall back to defaults on any read/parse error.
        }

        return new AppSettings();
    }

    public void Save()
    {
        try
        {
            string json = JsonSerializer.Serialize(this,
                new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(SettingsPath, json);
        }
        catch
        {
            // Persisting settings is best-effort; ignore failures.
        }
    }
}
