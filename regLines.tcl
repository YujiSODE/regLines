#regLines
#regLines.tcl
##===================================================================
#	Copyright (c) 2018 Yuji SODE <yuji.sode@gmail.com>
#
#	This software is released under the MIT License.
#	See LICENSE or http://opensource.org/licenses/mit-license.php
##===================================================================
#Tool for generating random variables that follows given frequency distibution using linear regressions in given intervals.
#=== Synopsis ===
#::regLines::reglines X Y ?name?;
#
#it outputs tcl script file that defines additional math functions (lines(x), linesPDF(x) and linesVar()) and returns generated filename
#   - $X and $Y: numerical lists for x-axis and y-axis
#   - $name: a text used in order to generate filename of output file, and numbers are default value
#     generated filename has a form of "${name}_regL.tcl"
#--------------------------------------------------------------------
#*** <namespace ::regLines> ***
#interface for linear regressions
# - proc getRange X: procedure that returns target data range
#   - $X: a numerical list for x-axis
#
# - proc getLine X Y: procedure for linear regression that returns result as a list
#   The returned list is {A B R2} representing model of "y=f(x)=Ax+B, and R2=Var(f)/Var(y)"
#   - $X: a numerical list for x-axis
#   - $Y: a numerical list for y-axis
#--------------------------------------------------------------------
#*** <namespace ::tcl::mathfunc> ***
#additional functions for regression analysis
#--- lSum.tcl (Yuji SODE, 2018): https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0 ---
# - lSum(list): function that returns sum of given list
#   - $list: a numerical list
#--------------------------------------------------------------------
# - avg(list): function that estimates average using a given numerical list
#   - $list: a numerical list
#
# - var(list): function that estimates variance using a numerical list and "list size -1"
#   - $list: a numerical list
#
# - cov(X,Y): function that estimates covariance using two numerical lists and "list size -1"
#   - $X: a numerical list for x-axis
#   - $Y: a numerical list for y-axis
#--------------------------------------------------------------------
#+++ function defined by output tcl script file +++
# - lines(x): function that returns estimated sample distribution
# - linesPDF(x): function that returns a value of probability density function estimated from the sample distribution
# - linesVar(): function that returns a random variable following PDF
#   - $x: a numerical value
##===================================================================
set auto_noexec 1;
package require Tcl 8.6;
#*** <namespace ::tcl::mathfunc> ***
#additional functions for regression analysis
namespace eval ::tcl::mathfunc {
	#=== lSum.tcl (Yuji SODE, 2018): https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0 ===
	#it returns sum of given list
	#Reference: Iri, M., and Fujino., Y. 1985. Suchi keisan no joshiki (Japanese). Kyoritsu Shuppan Co., Ltd. ISBN 978-4-320-01343-8
	proc lSum {list} {
		#=== lSum.tcl (Yuji SODE, 2018): https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0 ===
		#Reference: Iri, M., and Fujino., Y. 1985. Suchi keisan no joshiki (Japanese). Kyoritsu Shuppan Co., Ltd. ISBN 978-4-320-01343-8
		namespace path {::tcl::mathop};set S 0.0;set R 0.0;set T 0.0;foreach e $list {set R [+ $R [expr double($e)]];set T $S;set S [+ $S $R];set T [+ $S [expr {-$T}]];set R [+ $R [expr {-$T}]];};return $S;
	};
	#
	#it estimates average using a given numerical list
	proc avg {list} {
		# - $list: a numerical list
		set v {};
		#n is list size
		set n [expr {double([llength $list])}];
		foreach e $list {
			lappend v [expr {double($e)}];
		};
		return [expr {lSum($v)/$n}];
	};
	#it estimates variance using a numerical list and "list size -1"
	proc var {list} {
		# - $list: a numerical list
		set v {};
		#n is list size
		set n [expr {double([llength $list])}];
		#m is average of list
		set m [expr {avg($list)}];
		foreach e $list {
			lappend v [expr {(double($e)-$m)**2}];
		};
		unset m;
		return [expr {lSum($v)/($n-1)}];
	};
	#it estimates covariance using two numerical lists and "list size -1"
	proc cov {X Y} {
		# - $X: a numerical list for x-axis
		# - $Y: a numerical list for y-axis
		#set v 0.0;
		set v {};
		set i 0;set x0 0.0;set y0 0.0;
		#nX is list size of $X
		set nX [expr {double([llength $X])}];
		#mX is average of $X
		set mX [expr {avg($X)}];
		#mY is average of $Y
		set mY [expr {avg($Y)}];
		while {$i<$nX} {
			set x0 [expr {double([lindex $X $i])}];
			set y0 [expr {double([lindex $Y $i])}];
			lappend v [expr {($x0-$mX)*($y0-$mY)}];
			incr i 1;
		};
		unset mX mY i x0 y0;
		return [expr {lSum($v)/($nX-1)}];
	};
};
#*** <namespace ::regLines> ***
#interface for linear regressions
namespace eval ::regLines {
	#procedure that returns target data range
	proc getRange {X} {
		# - $X: a numerical list for x-axis
		set v {};
		set i 0.0;
		#rgEx is regular expression that matches real number
		set rgEx {^(?:[+-]?[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+(?:\.[0-9]+)?)?)$|^(?:\.[0-9]+)$};
		puts stdout {Please input data range (dx or x0 x1 ... xn)};
		set range [gets stdin];
		#data range size<1 or not real number element is in data range
		while {([llength $range]<1)||([lsearch -regexp $range $rgEx]<0)} {
			puts stdout {Please input data range (dx or x0 x1 ... xn)};
			set range [gets stdin];
		};
		#data range size>0
		#to remove duplications
		lsort -real -unique $range;
		if {[llength $range]<2} {
			#data range size=1
			#error is returned when input dx is not positive
			if {!($range>0)} {
				return -code error "ERROR: input dx is not positive";
			};
			set xSort [lsort -real -increasing $X];
			set i [format %.4f [lindex $xSort 0]];
			set max [format %.4f [lindex $xSort end]];
			while {$i<$max} {
				lappend v $i;
				set i [format %.4f [expr {$i+$range}]];
			};
			lappend v $max;
		} else {
			#data range size>1
			set v $range;
		};
		return $v;
	};
	#procedure for linear regression that returns result as a list
	#the returned list is {A B R2} representing model of "y=f(x)=Ax+B, and R2=Var(f)/Var(y)"
	proc getLine {X Y} {
		# - $X: a numerical list for x-axis
		# - $Y: a numerical list for y-axis
		if {([llength $X]<2)||([llength $Y]<2)} {return "0 0 0";};
		set f {};
		#=== linear model: y=Ax+B ===
		set A 0.0;
		set B 0.0;
		#R2 is coefficient of determination
		set R2 0.0;
		#averages of given values
		set avX [expr {avg($X)}];
		set avY [expr {avg($Y)}];
		#variances of given values
		set s2X [expr {var($X)}];
		set s2Y [expr {var($Y)}];
		#covariance of given values
		set sXY [expr {cov($X,$Y)}];
		#=== regression ===
		if {$s2X!=0} {
			#== when variance of X is not 0 ==
			set A [expr {$sXY/$s2X}];
			set B [expr {$avY-$A*$avX}];
			#coefficient of determination
			set f [lmap e $X {list [expr {$A*double($e)+$B}];}];
			set R2 [expr {($s2Y!=0)?var($f)/$s2Y:1}];
		} else {
			#== when variance of X is 0 ==
			#f(x!=c)=0 and f(x=c)=Inf
			set A "0@$avX";
			set B Inf;
			set R2 1;
		};
		unset avX avY s2X s2Y sXY f;
		#model: y=Ax+B
		return "$A $B $R2";
	};
	#it outputs tcl script file that defines additional math functions (lines(x), linesPDF(x) and linesVar()) and returns generated filename
	proc reglines {X Y {name {}}} {
		# - $X: a numerical list for x-axis
		# - $Y: a numerical list for y-axis
		# - $name: a text used in order to generate filename of output file, and numbers are default value
		#   generated filename has a form of "${name}_regL.tcl"
		if {[llength $X]!=[llength $Y]} {return -code error "ERROR: list sizes are different";};
		set fileName "[expr {[llength $name]>0?${name}:[clock seconds]}]_regL.tcl";
		#++++++ [module]:_mdl is script of output module ++++++
		set _mdl "\#$fileName\n";
		append _mdl "\#This script was generated using regLines.tcl\n";
		#area is area of estimated regression lines in given data range
		set area 0.0;
		#PDFMax is max value of estimated PDF in given data range
		set PDFMax {};
		#ch is channel to output
		set ch {};
		#dRange is data range list
		set dRange [lsort -real -increasing [::regLines::getRange $X]];
		set rgN [llength $dRange];
		#++++++ [module]: comment for data range ++++++
		append _mdl "\#data range: [lindex $dRange 0] to [lindex $dRange end]\n";
		append _mdl "\#break points: [join $dRange ,]\n";
		#++++++ [module]: function lSum ++++++
		append _mdl "\#it returns sum of given list\n";
		append _mdl "proc ::tcl::mathfunc::lSum \{list\} \{";
		append _mdl [info body ::tcl::mathfunc::lSum];
		#++++++ [module]: function lSum END +++++
		append _mdl "\}\;\n";
		set i 0;
		#dClassesX and dClassesY are arrays of classified values
		#numerical values are classified into data range size-1 classes and the others
		array set dClassesX {};
		array set dClassesY {};
		foreach e [lrange $dRange 0 end-1] {
			set dClassesX($e) {};
			set dClassesY($e) {};
		};
		#Lines is an array of lists that have parameters of a regression
		#Lines has data range size-1 elements
		array set Lines {};
		#=== x-value and y-value are classified based on data range ===
		foreach eX $X eY $Y {
			set eX [expr {double($eX)}];
			if {($eX<[lindex $dRange 0])||($eX>[lindex $dRange end])} {continue;};
			set i 0;
			while {$i<($rgN-1)} {
				if {($eX<[lindex $dRange $i+1])&&!($eX<[lindex $dRange $i])} {
					lappend dClassesX([lindex $dRange $i]) $eX;
					lappend dClassesY([lindex $dRange $i]) $eY;
				};
				incr i 1;
			};
			if {!($eX!=[lindex $dRange end])} {
				lappend dClassesX([lindex $dRange end-1]) $eX;
				lappend dClassesY([lindex $dRange end-1]) $eY;
			};
		};
		foreach eX [lrange $dRange 0 end-1] eY [lrange $dRange 0 end-1] {
			if {!([llength $dClassesX($eX)]>0)||!([llength $dClassesY($eY)]>0)} {
				set dClassesX($eX) 0;
				set dClassesY($eY) 0;
			};
		};
		#=== linear regressions ===
		#Lines is an array of lists that have parameters of a regression: {A B R2}
		#Lines has data range size-1 elements
		foreach e [lrange $dRange 0 end-1] {
			set Lines($e) [::regLines::getLine $dClassesX($e) $dClassesY($e)];
		};
		#estimating total area, max value and min value of regression lines in the given range
		set i 0;
		set aSub {};
		while {$i<($rgN-1)} {
			set e1 [lindex $dRange $i];
			set e1D [expr {double($e1)}];
			set e2 [lindex $dRange $i+1];
			set e2D [expr {double($e2)}];
			#values of regression lines
			set ax1 [expr {[lindex $Lines($e1) 1]!=Inf?double([lindex $Lines($e1) 0])*$e1D:Inf}];
			set ax2 [expr {[lindex $Lines($e1) 1]!=Inf?double([lindex $Lines($e1) 0])*$e2D:Inf}];
			if {$ax1!=Inf} {
				lappend ax1 [expr {double([lindex $Lines($e1) 1])}];
				lappend ax2 [expr {double([lindex $Lines($e1) 1])}];
				lappend PDFMax [expr {lSum($ax1)}];
				lappend PDFMax [expr {lSum($ax2)}];
			};
			if {[lindex $Lines($e1) 1]!=Inf} {
				#(A/2)*(x2**2) cf. f(x)=Ax+B
				lappend aSub [expr {(double([lindex $Lines($e1) 0])/2)*($e2D**2)}];
				#B*x2 cf. f(x)=Ax+B
				lappend aSub [expr {double([lindex $Lines($e1) 1])*$e2D}];
				#(-A/2)*(x1**2) cf. f(x)=Ax+B
				lappend aSub [expr {(-double([lindex $Lines($e1) 0])/2)*($e1D**2)}];
				#-B*x1 cf. f(x)=Ax+B
				lappend aSub [expr {-double([lindex $Lines($e1) 1])*$e1D}];
			};
			incr i 1;
		};
		set area [expr {lSum($aSub)}];
		set PDFMax [expr {double([lindex [lsort -real -increasing $PDFMax] end])/$area}];
		if {[llength $PDFMax]<1} {return -code error "ERROR: data ranges and/or regression lines are invalid";};
		unset e1 e2 e1D e2D aSub ax1 ax2;
		#++++++ [module]: function lines ++++++
		append _mdl "\#it returns estimated sample distribution\n";
		append _mdl "proc ::tcl::mathfunc::lines \{x\} \{\n";
		append _mdl "\tset X \[expr \{double\(\$x\)\}\]\;\n";
		append _mdl "\t\#R is data range\n";
		append _mdl "\tset R \{[lsort -real -increasing $dRange]\}\;\n";
		append _mdl "\t\#nR is data range size\n";
		append _mdl "\tset nR [llength $dRange]\;\n";
		append _mdl "\t\#l is an array of regression results: \{A B R2\} for y=Ax+B and coefficient of determination\n";
		foreach e [lsort -real -increasing [array names Lines]] {
			append _mdl "\tset l\($e\) \{$Lines($e)\}\;\n";
		};
		append _mdl "\tif \{\(\$X<[lindex $dRange 0]\)||\(\$X>[lindex $dRange end]\)\} \{return 0\;\} else \{\n";
		append _mdl "\t\tset i 0;while \{\$i<\(\$nR-1\)\} \{\n";
		append _mdl "\t\t\t\if \{\(\$X<\[lindex \$R \$i+1\]\)&&!\(\$X<\[lindex \$R \$i\]\)\} \{\n";
		#++++++ [module]: when Rmin < $X < Rmax ++++++
		#++++++ [module]: estimating value of f(x) +++++
		append _mdl "\t\t\t\tset e \[lindex \$R \$i\]\;if \{!\(\[lindex \$l\(\$e\) 1\]!=Inf\)\} \{\n";
		append _mdl "\t\t\t\t\treturn \[expr \{\$X!=\[string range \[lindex \$l\(\$e\) 0\] 2 end\]?0:Inf\}\]\;\n";
		append _mdl "\t\t\t\t\} else \{\n";
		append _mdl "\t\t\t\t\tset v \{\}\;\n";
		append _mdl "\t\t\t\t\tlappend v \[expr \{\[lindex \$l\(\$e\) 0\]*\$X\}\]\;lappend v \[lindex \$l\(\$e\) 1\]\;\n";
		append _mdl "\t\t\t\t\treturn \[expr \{lSum\(\$v\)\}\]\;\n";
		append _mdl "\t\t\t\t\}\;\n";
		#
		append _mdl "\t\t\t\}\;\n";
		append _mdl "\t\tincr i 1\;\}\;\n";
		#++++++ [module]: when $X = Rmax ++++++
		#++++++ [module]: estimating value of f(x) +++++
		append _mdl "\t\tset e \[lindex \$R end-1\]\;if \{!\(\[lindex \$l\(\$e\) 1\]!=Inf\)\} \{\n";
		append _mdl "\t\t\treturn \[expr \{\$X!=\[string range \[lindex \$l\(\$e\) 0\] 2 end\]?0:Inf\}\]\;\n";
		append _mdl "\t\t\} else \{\n";
		append _mdl "\t\t\tset v \{\}\;\n";
		append _mdl "\t\t\tlappend v \[expr \{\[lindex \$l\(\$e\) 0\]*\$X\}\]\;lappend v \[lindex \$l\(\$e\) 1\]\;\n";
		append _mdl "\t\t\treturn \[expr \{lSum\(\$v\)\}\]\;\n";
		append _mdl "\t\t\}\;\n";
		#
		append _mdl "\t\}\;\n";
		#++++++ [module]: function lines END +++++
		append _mdl "\}\;\n";
		#++++++ [module]: function linesPDF ++++++
		append _mdl "\#it returns a value of probability density function estimated from the sample distribution\n";
		append _mdl "proc ::tcl::mathfunc::linesPDF \{x\} \{\n";
		append _mdl "\treturn \[expr \{lines\(\$x\)/$area\}\]\;";
		#++++++ [module]: function linesPDF END +++++
		append _mdl "\}\;\n";
		#++++++ [module]: function linesVar ++++++
		append _mdl "\#it returns a random variable that follows PDF\n";
		append _mdl "proc ::tcl::mathfunc::linesVar \{\} \{\n";
		set dRg {};
		lappend dRg [expr -[lindex $dRange 0]];
		lappend dRg [lindex $dRange end];
		append _mdl "\tset Y \[expr \{double\([lindex $dRange 0]\)+double\([expr {lSum($dRg)}]\)*rand\(\)\}\]\;\n";
		append _mdl "\tset U \[expr rand\(\)\]\;\n";
		append _mdl "\tset v \[expr \{linesPDF\(\$Y\)/$PDFMax\}\]\;\n";
		append _mdl "\twhile \{\$U>\$v\} \{\n";
		append _mdl "\t\tset Y \[expr \{double\([lindex $dRange 0]\)+double\([expr {lSum($dRg)}]\)*rand\(\)\}\]\;\n";
		append _mdl "\t\tset U \[expr rand\(\)\]\;\n";
		append _mdl "\t\tset v \[expr \{linesPDF\(\$Y\)/$PDFMax\}\]\;\n";
		append _mdl "\t\}\;\n";
		append _mdl "\treturn \$Y\;\n";
		#++++++ [module]: function linesVar END +++++
		append _mdl "\}\;\n";
		#=== text log ===
		puts stdout "data range: [lindex $dRange 0] to [lindex $dRange end]";
		puts stdout "regression results: \{A B R2\} for y=Ax+B and coefficient of determination";
		parray Lines;
		puts stdout "max value of PDF:$PDFMax";
		#=== output of module file ===
		set ch [open $fileName w];
		fconfigure $ch -encoding utf-8;
		puts -nonewline $ch $_mdl;
		close $ch;unset ch _mdl;
		source -encoding utf-8 $fileName;
		return $fileName;
	};
};
