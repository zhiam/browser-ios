rm -rf brave
(cd ../../ && xcodebuild -exportLocalizations)
mv -f ../../Client/en.xliff .
./xliff-cleanup.py en.xliff
sed -i '' 's/Shared\/Supporting Files/brave/' en.xliff
git checkout -- brave
