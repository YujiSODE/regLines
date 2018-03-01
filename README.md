# regLines
Tool for generating random variables that follows given frequency distibution using linear regressions in given intervals.  
GitHub: https://github.com/YujiSODE/regLines  
>Copyright (c) 2017 Yuji SODE \<yuji.sode@gmail.com\>  
>This software is released under the MIT License.  
>See LICENSE or http://opensource.org/licenses/mit-license.php
______
## 1. Synopsis
`::regLines::reglines X Y ?name?;`  
it outputs tcl script file that defines additional math functions (`lines(x)`, `linesPDF(x)` and `linesVar()`) and returns generated filename
- `$X` and `$Y`: numerical lists for x-axis and y-axis
- `$name`: a text used in order to generate filename of output file, and numbers are default value.  
  generated filename has a form of `"${name}_regL.tcl"`

## 2. Script
It requires Tcl/Tk 8.6+.
- `regLines.tcl`
