# Notes

Not clear whether I'll revisit this project again.

Here are my notes for (potential) future reference.

## Front end

The front end is split in three phases

1. Preparser - split a source file into an array (linear) prepaser elements
    * Doc block (block of documentation). The block has begin and end (ie `/**` `*/`)
    * Doc line (a single line of documentation). End is determined by `\n`
    * Ignore block - string or non-doc comment for example
    * Ignore line
    * Scope block begin - the beginning of a scope
    * Scope block end - end of a scope
    * Indent scope begin - same but for indentation base scoping
    * Indent scope end
1. Parser - generate internal representation based on preparser data. A tree of elements
    * Doc element
        * Relevant code (the code which is documented by this)
        * Child elements
1. Symbolicator - works on relevant code to try to reason about it. Tries to find which symbols from the line are being documented (function, variable)

## Back end

Generate html or others