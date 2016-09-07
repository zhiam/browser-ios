copy_framework ()
{
    local framework=$1

    local file_path="$framework/`basename $framework .framework`"

    lipo -remove i386 "$file_path" -output "$file_path"
    lipo -remove x86_64 "$file_path" -output "$file_path"
    
}

for f in ../../Carthage/Build/iOS/*.framework; do
  copy_framework $f 
done
