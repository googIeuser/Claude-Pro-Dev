function Get-SignedTotal([string]$Csv) {
    $total = 0
    foreach ($part in $Csv.Split(',')) {
        if ($part.Trim()) { $total += [int]($part.Trim().TrimStart('-')) }
    }
    return $total
}
