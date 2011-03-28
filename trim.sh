#!/bin/sh
help(){
name=`basename $0`;less<<HLP
$name

Usage:
	$name
	$name [--all (ppc | i386)] [-p]
	$name [-a (ppc | i386)] [-s] [-n] [-d] [-t] [-p]

Options:
	--all architecture
		Same as setting '-d -n -s -t -r'
		If architecture is set, strips universal binaries
	-a architecture
		Strip universal binaries. Keep architecture specified, delete others
	-d
		Remove useless files
	-n
		Compile and trim nibs
	-s
		Strip debug symbols from binaries
	-t
		Compress tiff images (lzw)
	-r
		Remove resource forks
	-p
		Print list files deleted

Examples:
	$name
Prompt for architecture and if not blank, clean out universal binaries
Strip debug symbols, remove junk files, trim nib files compress tiffs
	$name --all ppc
Keep ppc code, remove intel code
Strip debug symbols, remove junk files, trim nib files, compress tiffs
	$name --all
Strip debug symbols, remove junk files, trim nib files, compress tiffs
Does not strip universal binaries
	$name -d -p
Remove .DS_Store files in working directory and subdirectories
Print a list of deleted files
HLP
exit 0;}
if [ -z "$1" ];then nibs=1;ds_rm=1;strip=1;tif=1;res=1;printf "Architecture to keep? (ppc/i386) ";read -r arch; else while [ -n "$1" ];do case $1 in
-h)help;shift 1;;-d)ds_rm=1;shift 1;;-t)tif=1;shift 1;;-r)res=1;shift 1;;-n)nibs=1;shift 1;;-s)strip=1;shift 1;;-a)if [ -z "$2" ];then echo "error: no architecture after -a" 1>&2;exit 1;else arch=$2;shift 2;fi;;-p)otpt=' -ls';shift 1;;--all)nibs=1;ds_rm=1;strip=1;tif=1;res=1;shift 1;if [ "$1" != "-p" ]&&[ "$1" != "--" ];then arch=$1;shift 1;fi;;--)dir=$2;shift;break;;-*)echo "error: no such option $1" 1>&2;exit 1;;*)break;;
esac;done;fi
[ -n "$dir" ]||dir=".";[ -n "$ds_rm" ]&&{
echo " ==  Removing junk files...";find $dir \( -name .DS_Store -or -name pbdevelopment.plist \) | while read LINE;do rm "$LINE"&&[ "$otpt" ]&&echo "rm $LINE"
done;}
[ -n "$nibs" ]&&{
echo " ==  Trimming nibs...";find $dir \( -name info.nib -or -name classes.nib -or -name data.dependency \) | while read LINE;do
rm "$LINE"&&[ "$otpt" ]&&echo "rm $LINE"
done;}
[ -n "$res" ]&&{
echo " ==  Removing resource forks...";touch ../blank.tmp;find "$dir" -type f | while read LINE;do [ -s "$LINE/rsrc" ]&&cp ../blank.tmp "$LINE/rsrc"&&[ "$otpt" ]&&echo "cleaned $LINE"
done;rm ../blank.tmp;}
[ -n "$tif" ]&&{
echo " ==  Compressing tiff images...";find "$dir" \( -name \*.tif -or -name \*.tiff \) | while read LINE;do [ -w "$LINE" ]&&tiffutil -lzw "$LINE" -out "$LINE.out" 2>/dev/null&&mv "$LINE.out" "$LINE"&&[ "$otpt" ]&&echo "compressed $LINE"
done;}
[ -n "$arch" ]&&{
echo " ==  Trimming universal binaries...";here=`pwd`;find "$dir" \! -empty -and -type f > found.tmp;file -f found.tmp -kn | grep 'fat file' | sed -e 's/: *Mach.*//g' | while read LINE;do b_path=`dirname "$LINE"`;b_name=`basename "$LINE"`;eval cd "'$b_path'";eval lipo "'$b_name' -thin '$arch' -output '$b_name.lipo'"&&eval mv "'$b_name.lipo'" "'$b_name'";[ "$otpt" ]&&echo "trimmed $LINE";eval cd "'$here'"
done;}
[ -n "$strip" ]&&{
[ "$here" ]||{
here=`pwd`;find "$dir" \! -empty -and -type f >found.tmp;}
echo " ==  Stripping debug symbols...";file -f found.tmp -kn | grep Mach | sed -E 's/(\(for architecture [[:alnum:]]+\))?:[[:space:]]*(setuid )?Mach-O.*//g' | while read LINE;do b_path=`dirname "$LINE"`;b_name=`basename "$LINE"`;eval cd "'$b_path'";eval /Developer/Library/PrivateFrameworks/DevToolsCore.framework/Versions/A/Resources/pbxcp -resolve-src-symlinks -strip-debug-symbols "'$b_name'" ..;eval mv "'../$b_name'" .;[ "$otpt" ]&&echo "stripped $LINE";eval cd "'$here'"
done;}
[ -f found.tmp ]&&rm found.tmp;echo "Done.";exit 0