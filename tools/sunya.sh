#!/bin/sh

set -e

usage()
{
    echo "Usage:                        "
    echo "           $0 <project name>  "
    echo "                              "

    return 0
}

if test $# -ne 1; then
    usage
    exit 1
fi

NAME=$1
MYHOME=$PWD

cat > .gitignore <<EOF
./$0
*.udb
.DS_Store
*.tags
*.gz
*.tar
*.zip
*~
EOF

git init && git add . && git commit -m "Initial check-ins."

mkdir -p doc tools .vscode
cp $0 tools

cat > README.md <<EOF
$NAME
================

Hacking just for fun, $NAME.
EOF

cat > VERSION <<EOF
$NAME
EOF

cat > Makefile <<EOF

all: usage 

usage:
	@echo "Usage:                                                   "
	@echo "                                                         "
	@echo "    make  command                                        "
	@echo "                                                         "
	@echo "The commands are:                                        "
	@echo "                                                         "
	@echo "    build       build system                             "
	@echo "    tests       run make tests                           "
	@echo "    clean       remove object files                      "
	@echo "    fmt         run code format                          "
	@echo "    crefs       generate cross-reference in html format  "
	@echo "    pdf         generate cross-reference in pdf format   "
	@echo "    status      run git status                           "
	@echo "                                                         "

build:
	cd $NAME && make

fmt:
	cd $NAME && make format

tests:
	cd $NAME && make check

status:
	git status .

.PHONE: clean tests

clean:
	find . -name \*~ -type f |xargs -I {} rm -f {}

pdf: crefs
	ebook-convert cref/$NAME/src/index.html doc/$NAME.pdf \\
		--override-profile-size \\
		--paper-size a4 \\
		--pdf-default-font-size 12 \\
		--pdf-mono-font-size 12 \\
		--margin-left 10 --margin-right 10 \\
		--margin-top 10 --margin-bottom 10 \\
		--page-breaks-before='/'

crefs:
	src2html.pl --navigator --color --cross-reference --line-numbers \\
		--jobs 1 -o cref $NAME/src $NAME

openpdf: doc/$NAME.pdf
	open $<

openhtml: cref/$NAME/src/index.html
	open $<

sunya:
	rm -rf .vscode .git .gitignore tools doc VERSION README.md Makefile LICENSE AUTHORS
EOF

cat > LICENSE <<EOF
// Copyright (c) 2013-2018 The $NAME Authors. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software and
// its documentation for any purpose and without fee is hereby
// granted, provided that the above copyright notice appear in all
// copies and that both the copyright notice and this permission
// notice and warranty disclaimer appear in supporting
// documentation, and that the name of Lucent Technologies or any of
// its entities not be used in advertising or publicity pertaining
// to distribution of the software without specific, written prior
// permission.

// LUCENT TECHNOLOGIES DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
// SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS.  IN NO EVENT SHALL LUCENT OR ANY OF ITS ENTITIES BE
// LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
// DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
// WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
// ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.
EOF

cat > AUTHORS <<EOF
# This is the official list of $NAME authors for copyright purposes.
# This file is distinct from the CONTRIBUTORS files.
# See the latter for an explanation.

GuiQuan Zhang <guiqzhang at gmail.com>
yibit <yibitx at 126.com>
EOF

cat > .vscode/settings.json <<EOF
{
    "files.associations": {
        "*.h": "c",
        "*.c": "c",
        "*.sh": "shellscript",
        "*.lua": "lua",
        "*.go": "go"
    },
    "files.encoding": "utf8",
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "**/*.o": true,
        "**/*.gz": true,
        "**/*.tar": true,
        "**/*.zip": true
    }
}
EOF

SRC_DIR=$NAME/src
if test ! -d $SRC_DIR; then
    SRC_DIR=$NAME
fi
CLANG_FORMAT=$SRC_DIR/.clang-format

cat > $CLANG_FORMAT <<EOF
# Run manually to reformat a file:
# clang-format -i --style=file <file>
BasedOnStyle: Google
DerivePointerAlignment: false
SortIncludes: false
IndentWidth: 4
BreakBeforeBraces: Custom
BraceWrapping:
  AfterEnum: true
  AfterStruct: false
  AfterFunction: true
AlwaysBreakAfterReturnType: TopLevelDefinitions
IndentCaseLabels: false
AlignAfterOpenBracket: Align
AlignConsecutiveAssignments: false 
AlignConsecutiveDeclarations: false
AlignEscapedNewlinesLeft: true
AlignOperands: true
AlignTrailingComments: true
PointerAlignment: Right
AllowShortBlocksOnASingleLine: false
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: All
AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false
EOF

cat >> $NAME/Makefile <<EOF

format:
	cd ../$SRC_DIR && find . -name "*.[h|c]" |xargs -I {} clang-format -i --style=file {}
EOF
