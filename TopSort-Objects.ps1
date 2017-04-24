<#
.SYNOPSIS
    Topological sort of dependency graph (or any DAG)
.INPUTS
    List of lists of objects (or strings). Each inner list consists of an object (the head of the list) and other
    objects ON WHICH it depends.  Thing A "depends" on Thing B if Thing B must be processed before Thing A.
.OUTPUTS
    List of input objects sorted in such a way that objects that don't depend on anything occur before objects which
    depend on them.  (You could consider that to be a reverse-topological sort.)
.EXAMPLE
    TopSort-Objects @( @(10,11,3), @(9,11,8), @(2,11), @(8,7,3), @(11,5,7), @(3), @(7), @(5))
    
    Example from the Wikipedia page.
.EXAMPLE
    TopSort-Objects @( @("MSSQLSERVER", "SQLSERVERAGENT", "MSSQLFDLauncher", "SQLWriter"),
                       @("MSSQLSERVER", "W3SVC"),
                       @("W3SVC", "VisualWorkflowService"),
                       @("W3SVC", "GatewayAgent{0}{1}" ),
                       @("W3SVC", "HeliosConnectAgent{0}{1}"))

    Dependency here means "must be shut down after". Given that some services (first in each list) cannot/should not be
    stopped before other services (other elements of lists), produces an order in which services can be stopped so as
    not to violate these constraints.

    You can reverse the list to get the startup order for these same services.
#>

function TopSort-Objects
{
    param(
        [object[]]
        # Array of arrays. First element of each inner array is an object (or string), following elements are objects ON
        # WHICH the first object depends.
        $Dependencies

        #
    )

    $wrapper = Wrap-Dependencies $Dependencies
    $sorted = Sort-Tarjan $wrapper

    $sorted | % {$_.Value}
    #
}

<#
.SYNOPSIS
    Wrap objects in given dependency lists in graph nodes for processing.
.INPUTS
    Same as inputs to TopSort-Objects.
.OUTPUTS
    A hashtable map of input objects to object wrappers. Each wrapper has the following properties:

    - Value : The original input object being wrapped
    - Dependencies : A Collections.ArrayList of (wrapped) objects ON WHICH the current object depends
    - TempMark: A boolean indicating whether or not the current object is temporarily marked (Tarjan algorithm)
    - PermMark: A boolean indicating whether or not the current object is permanently marked (Tarjan algorithm)
#>
function Wrap-Dependencies
{
    param(
        [object[]]
        # Array of arrays, as described as the input for TopSort-Objects. First element of each inner array is an object
        # (or string), following elements are objects ON WHICH the first object depends.
        $aDeps
    )

    # Map from dependency object (or string) to wrapper node wrapping that object
    $retval = new-object Hashtable

    foreach ($depsList in $aDeps) {
        $head = $Null
        foreach ($dep in $depsList) {
            if ($retval.ContainsKey( $dep)) {
                $wrappedDep = $retval[$dep] }
            else {
                $wrappedDep = [PSCustomObject]@{Value=$dep; Dependencies=(new-object Collections.ArrayList); TempMark=$False; PermMark=$False}
                $retval[$dep] = $wrappedDep }
            if ($head -eq $Null) {
                $head = $wrappedDep }
            else {
                $head.Dependencies.Add( $wrappedDep) }
        }
    }

    return $retval
}

<#
.SYNOPSIS
    Applies the Tarjan algorithm to sort the graph.
.INPUTS
    A hashtable of object wrappers, as described for the output of Wrap-Dependencies
.OUTPUT
    A Collections.ArrayList of wrapper, sorted topologically (TODO: most-dependent first? least-dependent first?)
#>
function Sort-Tarjan
{
    param(
        [object]
        # A hashtable as described as the output of Wrap-Dependencies.
        $aWrapperMap
    )

    $retval = new-object Collections.ArrayList
    $unmarkedNode = Get-UnmarkedNode $aWrapperMap
    while ($unmarkedNode -ne $Null)
    {
        [void](Visit-Node $unmarkedNode $retval)
        $unmarkedNode = Get-UnmarkedNode $aWrapperMap
    }

    return $retval
    #
}

function Get-UnmarkedNode
{
    param(
        [object]
        # Hashtable as produced by Wrap-Dependencies
        $aWrapperMap
    )

    $retval = $Null
    # TODO: this is inefficient (gives O(n^2) time). We should build a queue of the values initially and just work
    # through it.
    foreach ($node in $aWrapperMap.Values)
    {
        if (-not $node.PermMark)
        {
            $retval = $node
            break
        }
    }
    return $retval
    #
}

<#
.SYNOPSIS
    See https://en.wikipedia.org/wiki/Topological_sorting#Tarjan.27s_algorithm
.INPUTS
    A wrapper node in a graph produced by Wrap-Dependencies
.OUTPUTS
    None, but updates nodes in the graph
#>
function Visit-Node
{
    param(
        [object]
        # The node to visit
        $n,

        [object]
        # ArrayList of sorted nodes, will append new values to end
        $sortedNodes
    )

    if ($n.TempMark) {
        throw "Circular dependencies: given dependency graph is not a DAG (Directed Acyclic Graph)"
    }
    if ($n.PermMark) {}
    else {
        $n.TempMark = $True
        foreach ($m in $n.Dependencies) {
            Visit-Node $m $sortedNodes
        }
        $n.PermMark = $True
        $n.TempMark = $False
        $sortedNodes.Add( $n)
    }
}

