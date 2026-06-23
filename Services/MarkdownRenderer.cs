using Markdig;

namespace MarkdownViewer.Services;

/// <summary>
/// Converts Markdown source text into an HTML fragment using Markdig with the
/// advanced (GitHub-Flavored) extension set enabled.
/// </summary>
public static class MarkdownRenderer
{
    private static readonly MarkdownPipeline Pipeline = new MarkdownPipelineBuilder()
        .UseAdvancedExtensions()   // tables, task lists, strikethrough, autolinks, footnotes, etc.
        .UseEmojiAndSmiley()
        .Build();

    /// <summary>
    /// Renders the given Markdown text to an HTML body fragment.
    /// </summary>
    public static string ToHtml(string markdown) => Markdown.ToHtml(markdown, Pipeline);
}
