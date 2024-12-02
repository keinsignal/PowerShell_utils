<#
.NOTES
PWGen.ps1
Author: ehillman@stauer.com
Date: 20 Dec 2017
Company: Nextten Stauer, LLC

.SYNOPSIS
A really basic pwgen script.

.DESCRIPTION
I gen pws

.PARAMETER Length
Number of characters per password (default 16)

.PARAMETER Count
Number of passwords to generate (default 16)

.PARAMETER Charset
An array of valid ASCII character values (default 48..122, which includes all alphanums plus :;<=>?@[\]^_` )
Some useful values:
    @(48..57) => numerals only
    @([char]'A'..[char]'Z') => uppercase letters
    'abcdefghijkmnpqrstuvwxyz23456789'.ToCharArray()  => all lower-case letters and numbers except l, o, 1, and 0.
    @(48..57 + 65..90 + 95 + 97..122) => all numerals, letters, and the underscore character (same as regex '\w')

.EXAMPLE
PWGen.ps1
Output:
    Ttx>gbO8V<k6<w]C
    Iaq0QNb@o[<m\OsZ
    3s8N?x\B;R=>nVkl
    ?zug4?OrKGS2hA41
    >GAX`LQnz5Jz\jS]
    @A48EGTu5wDU[;yc
    `n_wT]6qH`s^F2AF
    NCOxO1M>6uhNinOU
    aDPxX?U>2LCFl;Cs
    BNpPbC9=nmfFp_fT
    CktAK7?icbCjT5Z5
    I5]BR0eSk=AWZxMG
    :>AuWmeH@JK;nS9I
    qhy2Ub>1fsh;fGke
    :xOHxnn?DC2kxvZ9
    ENYZwgA^RTUuq9\i

Default behavior - output sixteen random 16-character passwords.
    

.EXAMPLE
PWGen.ps1 -c 3 -l 8
Output:
    V6ka5wpX
    \v`tUF:\
    y]Tfhs]j

Short param names are allowed.

.EXAMPLE
PWGen.ps1 8 4
Output:       
    rtjH?hC[
    Fd[3Qnz]
    HA?P@NiM
    iIEL;WCD

"-Length" and "-Count" are positional paramaters.

.EXAMPLE
PWGen.ps1 -c 3 -l 4 -cset '1234567890'.ToCharArray()   
Output:
    2382
    2001
    6485

Generates three random 4-digit PINs.

#>

#Requires -Version 2.0

[CmdletBinding()]
PARAM( 
    [Parameter(Position=0)]
    [Alias('l')]
    [int]$Length=16, 

    [Parameter(Position=1)]
    [Alias('c')]
    [string]$Count=16,
  
    [Alias('cset')]
    [array] $Charset = @(48..122)
)

## Note that if you are writing a script that only exports a function, help text should be inside your
## function block, or right before it.

Begin {
    $permitted = @(32..126) # Only ASCII printable characters allowed here.
    if (compare-object $Charset $permitted | ? { $_.SideIndicator -eq '<=' }) { 
        Throw "Illegal characters in -Charset"
    }
}

Process {
    for ($i = 0; $i -lt $Count; $i++) {
        $string = [string]''
        for ($i2 = 0; $i2 -lt $Length; $i2++) {
            $string += [char] $(Get-Random -InputObject $Charset)
        }
        Write-Output $string
    }
}
End {
    Remove-Variable string
}