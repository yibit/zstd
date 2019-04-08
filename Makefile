
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
	cd zstd-1.3.8 && make

fmt:
	cd zstd-1.3.8 && make format

tests:
	cd zstd-1.3.8 && make check

status:
	git status .

.PHONE: clean tests

clean:
	find . -name \*~ -type f |xargs -I {} rm -f {}

pdf: crefs
	ebook-convert cref/zstd-1.3.8/src/index.html doc/zstd-1.3.8.pdf \
		--override-profile-size \
		--paper-size a4 \
		--pdf-default-font-size 12 \
		--pdf-mono-font-size 12 \
		--margin-left 10 --margin-right 10 \
		--margin-top 10 --margin-bottom 10 \
		--page-breaks-before='/'

crefs:
	src2html.pl --navigator --color --cross-reference --line-numbers \
		--jobs 1 -o cref zstd-1.3.8/src zstd-1.3.8

openpdf: doc/zstd-1.3.8.pdf
	open $<

openhtml: cref/zstd-1.3.8/src/index.html
	open $<

sunya:
	rm -rf .vscode .git .gitignore tools doc VERSION README.md Makefile LICENSE AUTHORS
