echo "<========================>"
echo "/output"
ls /build/output

echo "/previousOutput"
echo "<========================>"
ls /build/previousOutput
cat /build/previousOutput/test.js
echo "<========================>"


echo "hello once" >> /build/output/test2.js
