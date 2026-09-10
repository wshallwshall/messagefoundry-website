# Use STE100 for technical document prose

The technical PDFs use [ASD-STE100 Issue 9](https://www.asd-ste100.org/about_STE.html) as their writing reference.

Use the standard's dictionary meanings and parts of speech. Keep one technical term for each concept. Product names, protocol names, API names, and configuration keys retain their exact spelling.

Write one action per instruction. Put a necessary condition before the action. Use active voice and direct commands. Instructions have at most 20 words per sentence. Descriptions have at most 25 words per sentence. Do not use contractions or semicolons in editable prose.

These rules apply to table explanations as well as paragraphs. Preserve values, limits, exceptions, and links when you divide long text.

Do not rewrite code, quoted text, or binding legal and security requirements for style. Explain them in separate prose where needed. Historical evidence retains its dates and scope.

The September 2026 copy pass applied these rules to document explanations and procedures. Protected source text remains unchanged. Some dense technical table explanations still exceed the sentence limits. This record does not claim full-document STE100 conformance or certification.

Edit the Markdown sources before you regenerate PDFs. Follow the renderer instructions in [the PDF source README](../assets/docs/_md/README.md). Inspect page layout and extracted text after each build.
