/*
 * Utility functions for testing various things (on a manual basis).
 */
(function() {

  function isSymmetric(matrix) {
    
    var len = matrix.length;

    for (var i = 0; i < len; i++) {

      if (matrix[i].length != len) return false;

      for (var j = 0; j < len; j++) {

        if (isNaN(matrix[i][j]) && isNaN(matrix[j][i])) continue;
        if (matrix[i][j] !== matrix[j][i]) return false;
      }
    }

    return true;
  }

  function testSubNetwork(net, subnet, indices, netMat, subMat) {

    printMatrix(subMat);

    var nnodes  = indices.length;

    if (subnet.nodes.length != nnodes) {
      throw "Wrong number of nodes in subnet";
    }
    
    for (var i = 0; i < nnodes; i++) {
      for (var j = 0; j < nnodes; j++) {

        if (i == j) continue;

        var fi = indices[i];
        var fj = indices[j];

        var shouldBeSubEdge  = !isNaN(subMat[ i][ j]);
        var shouldBeFullEdge = !isNaN(netMat[fi][fj]);
        var isSubEdge        = false;
        var isFullEdge       = false;


        // check that edge exists in subnet
        for (var n = 0; n < subnet.nodes[i].neighbours.length; n++) {
          if (subnet.nodes[i].neighbours[n].index === j) {
            isSubEdge = true;
            break;
          }
        }

        // check that edge exists in full net
        for (var n = 0; n < network.nodes[fi].neighbours.length; n++) {
          if (network.nodes[fi].neighbours[n].index === fj) {
            isFullEdge = true;
            break;
          }
        }

        if ((shouldBeFullEdge === isFullEdge) !== (shouldBeSubEdge === isSubEdge)) {

          console.log("shouldBeFullEdge " + shouldBeFullEdge);
          console.log("shouldBeSubEdge  " + shouldBeSubEdge);
          console.log("isSubEdge        " + isSubEdge);
          console.log("isFullEdge       " + isFullEdge);
          throw i + " and " + j;
        }

        
      }
    }

    console.log("Subnet is grand");
  }


  function printMatrix(matrix) {

    console.log(matrix);

    var fmt = d3.format("5.2f");

    matrix.forEach(function(row) {
      var strs = row.map(function(val) {return fmt(val);});
      console.log(strs.join("  "));
    });
  }


  function testNetwork(network, matrix) {

    var numNodes = network.nodes.length;

    for (var i = 0; i < numNodes; i++) {
      for (var j = 0; j < numNodes; j++) {


        var shouldBeEdge = !isNaN(matrix[i][j]);        
        if (i === j) shouldBeEdge = false;
        var jNeighbour = false; 
        var iNeighbour = false;
        var iEdge      = false;
        var jEdge      = false;
        var iOwnEdge   = true;
        var jOwnEdge   = true;
        var edgeExists = false;

        // test that j is a neighbour of i
        for (var n = 0; n < network.nodes[i].neighbours.length; n++) {
          
          if (network.nodes[i].neighbours[n].index === j) {
            jNeighbour = true;
            break;
          }            
        }

        // test that j is in the edges for i
        // and test that all of the edges for i contain i itself
        for (var e = 0; e < network.nodes[i].edges.length; e++) {

          var ei = network.nodes[i].edges[e].i.index;
          var ej = network.nodes[i].edges[e].j.index;

//          console.log("Testing " + i + " - " + j + " / " + ei + " - " + ej);

          if ([ei,ej].indexOf(i) === -1) 
            iOwnEdge = false;

          if (i !== j && [ei,ej].indexOf(j) > -1) 
            jEdge  = true;
        }

        // Do all that again the other way around
        for (var n = 0; n < network.nodes[j].neighbours.length; n++) {
          
          if (network.nodes[j].neighbours[n].index === i) {
            iNeighbour = true;
            break;
          }            
        }

       // test that j is in the edges for i
        // and test that all of the edges for i contain i itself
        for (var e = 0; e < network.nodes[j].edges.length; e++) {

          var ei = network.nodes[j].edges[e].i.index;
          var ej = network.nodes[j].edges[e].j.index;

          if ([ei,ej].indexOf(j) === -1) 
            jOwnEdge = false;
          if (j !== i && [ei,ej].indexOf(i) > -1) 
            iEdge  = true;
        }

        // test that the edge exists in network.edges
        for (var e = 0; e < network.edges.length; e++) {
          if (network.edges[e].i.index == Math.min(i,j) &&
              network.edges[e].j.index == Math.max(i,j)) {
            edgeExists = true;
            break;
          }
        }

        if (!iOwnEdge) throw i + " is missing itself";
        if (!jOwnEdge) throw j + " is missing itself";

        if (shouldBeEdge) {
          if (!(iNeighbour &&
                jNeighbour &&
                iEdge &&
                jEdge &&
                edgeExists)) {

            console.log("iNeighbour " + iNeighbour);
            console.log("jNeighbour " + jNeighbour);
            console.log("iEdge      " + iEdge);
            console.log("jEdge      " + jEdge);
            console.log("iOwnEdge   " + iOwnEdge);
            console.log("jOwnEdge   " + jOwnEdge);
            console.log("edgeExists " + edgeExists);

            throw "Edge should exist " + i + " -- " + j;
          }
        }
        else {
          if (jNeighbour ||
              iNeighbour ||
              jEdge      ||
              iEdge      ||
              edgeExists) {
            console.log("iNeighbour " + iNeighbour);
            console.log("jNeighbour " + jNeighbour);
            console.log("iEdge      " + iEdge);
            console.log("jEdge      " + jEdge);
            console.log("iOwnEdge   " + iOwnEdge);
            console.log("jOwnEdge   " + jOwnEdge);
            console.log("edgeExists " + edgeExists);

            throw "Edge shouldn't exist " + i + " -- " + j;
          }
        }
      }
    }

    console.log("Network is grand");
  }


});
