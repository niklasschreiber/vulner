import org.custommonkey.xmlunit.*;
import org.xml.sax.SAXException;

// Get XML documents
def request = context.expand( '${Request 1#Response}' )
def response = context.expand( '${Request 2#Response}' )

// Creates a list of elements to ignore
Set<String> ignoreList = new HashSet<String>();
ignoreList.add("dateTime")
ignoreList.add("packageId")

// Create an object with differences between documents
Diff myDiff = new Diff(request, response)
DetailedDiff diff = new DetailedDiff(myDiff);

// Get a list of all differences
List allDifferences = diff.getAllDifferences();

// Loop through all differences and find their node names
for (int i = 0; i < allDifferences.size(); i++) {
    diffNodeName =""

    // Check the node type to get the right node name
    nodeType = allDifferences.get(i).getTestNodeDetail().getNode().getNodeType()

    if (nodeType == 1) {

        // Get the name of the node if the difference is in the comment
        diffNodeName = allDifferences.get(i).getTestNodeDetail().getNode().getNodeName()
    } else {

    // Get the name of the parent node if the difference is not in the comment
    diffNodeName = allDifferences.get(i).getControlNodeDetail().getNode().getParentNode().getNodeName()
    }

    // Make sure that the node with a difference is not on the list of nodes to ignore
    if (!ignoreList.contains(diffNodeName)) {

        // Fail assertion
         assert false
    }
}

assert true