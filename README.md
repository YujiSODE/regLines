# regLines
Tool for generating random variables that follows given frequency distibution using linear regressions in given intervals.  
GitHub: https://github.com/YujiSODE/regLines  
Wiki: https://github.com/YujiSODE/regLines/wiki  
>Copyright (c) 2018 Yuji SODE \<yuji.sode@gmail.com\>  
>This software is released under the MIT License.  
>See LICENSE or http://opensource.org/licenses/mit-license.php
______
## 1. Synopsis
`::regLines::reglines X Y ?name?;`  
it outputs tcl script file that defines additional math functions (`lines(x)`, `linesPDF(x)` and `linesVar()`) and returns generated filename
- `$X` and `$Y`: numerical lists for x-axis and y-axis
- `$name`: a text used in order to generate filename of output file, and numbers are default value.  
  generated filename has a form of `"${name}_regL.tcl"`
### Input data ranges for linear regressions
Two expressions are available for linear regressions.
1. `dx`
2. `x0 x1 ... xn`

## 2. Script
It requires Tcl/Tk 8.6+.
- `regLines.tcl`

## 3. Library list
- lSum/lSum.tcl (Yuji SODE, 2018): https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0
