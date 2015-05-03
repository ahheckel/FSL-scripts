/*
 * Load, create, and modify objects representing networks.
 * 
 * Author: Paul McCarthy <pauldmccarthy@gmail.com>
 */
define(["lib/d3", "lib/queue"], function(d3, queue) {

  /*
   * Generates D3 colour (and edge width) scales for the given
   * network, and attaches them as attributes of the given 
   * scaleInfo object.
   *
   * It is assumed that the scaleInfo object already has the following 
   * properties:
   *
   *   - edgeWidthIdx:  Index of the edge weight to be used
   *                    for scaling edge widths.
   *
   *   - edgeColourIdx: Index of the edge weight to be used
   *                    for scaling edge colours.
   *
   *   - nodeColourIdx: Index of the node data to be used for
   *                    scaling node colours.
   *
   * The following attributes are added to the scaleInfo object:
   *
   *   - nodeColourScale:     Colours nodes according to the 
   *                          node data at nodeColourIdx.
   *
   *   - edgeWidthScale:      Scales edge widths according to the edge 
   *                          weight at index edgeWidthIdx.
   *
   *   - defEdgeColourScale:  Colours edges, when not highlighted, 
   *                          according to the edge weight at index 
   *                          edgeColourIdx.
   *
   *   - hltEdgeColourScale:  Colours edges, when highlighted, 
   *                          according to the edge weight at 
   *                          index edgeColourIdx.
   * 
   *   - nodeColour:          Function which takes a node object,
   *                          and returns a colour for it.
   *
   *   - defEdgeColour:       Function which takes an edge object,
   *                          and returns a default colour for it.
   *
   *   - hltEdgeColour:       Function which takes an edge object,
   *                          and returns a highlight colour for it.
   *
   *   - edgeWidth:           Function which takes an edge object,
   *                          and returns a width for it.
   *
   *   - *Path*:              Same as the above *Edge* functions, 
   *                          except these ones accept an object
   *                          which is assumed to have an edge 
   *                          object as an attribute called 'edge'.
   */
  function genColourScales(network, scaleInfo) {
    
    var ewwIdx = scaleInfo.edgeWidthIdx;
    var ecwIdx = scaleInfo.edgeColourIdx;

    // Nodes are coloured according to their node data.
    // TODO handle more than 10 node labels?
    var nodeColourScale = d3.scale.category10();

    var ecMin = network.matrixAbsMins[ecwIdx];
    var ecMax = network.matrixAbsMaxs[ecwIdx];
    var ewMin = network.matrixAbsMins[ewwIdx];
    var ewMax = network.matrixAbsMaxs[ewwIdx];

    // Edge width scale
    var edgeWidthScale = d3.scale.linear()
      .domain([-ewMax, -ewMin, -0, ewMin, ewMax])
      .range( [ 15,     1,      0, 1,     15]);

    // Colour scale for highlighted edges
    var hltEdgeColourScale = d3.scale.linear()
      .domain([ -ecMax,   0,          ecMax  ])
      .range( ["#0000dd", "#eeeeee", "#dd0000"]);

    // The colour scale for non-highlighted edges
    // is a washed out version of that used for 
    // highlighted edges. Could achieve the same
    // effect with opacity, but avoiding opacity
    // gives better performance.
    var edgeColourHltToDef = d3.scale.linear()
      .domain([0,   255])
      .range( [210, 240]);

    var defEdgeColourScale = function(val) {
      var c = d3.rgb(hltEdgeColourScale(val));
      
      var cols = [c.r,c.g,c.b];
      cols.sort(function(a,b) {return a-b;});

      var ri = cols.indexOf(c.r);
      var gi = cols.indexOf(c.g);
      var bi = cols.indexOf(c.b);

      c.r = Math.ceil(edgeColourHltToDef(cols[ri]));
      c.g = Math.ceil(edgeColourHltToDef(cols[gi]));
      c.b = Math.ceil(edgeColourHltToDef(cols[bi]));

      return c;
    }

    // attach all those scales as attributes 
    // of the provided scaleinfo object
    scaleInfo.nodeColourScale    = nodeColourScale;
    scaleInfo.edgeWidthScale     = edgeWidthScale;
    scaleInfo.defEdgeColourScale = defEdgeColourScale;
    scaleInfo.hltEdgeColourScale = hltEdgeColourScale;

    
    // And attach a bunch of convenience 
    // functions for use in d3 attr calls
    scaleInfo.nodeColour = function(node) {
      return scaleInfo.nodeColourScale(
        node.nodeData[network.scaleInfo.nodeColourIdx]);
    };

    scaleInfo.defEdgeColour = function(edge) {
      return scaleInfo.defEdgeColourScale(
        edge.weights[scaleInfo.edgeColourIdx]);
    };
    
    // The *Path* functions are provided, as 
    // edges are represented as spline paths
    // (see netvis.js)
    scaleInfo.defPathColour = function(path) {
      return scaleInfo.defEdgeColourScale(
        path.edge.weights[scaleInfo.edgeColourIdx]);
    };

    scaleInfo.hltEdgeColour = function(edge) {
      return scaleInfo.hltEdgeColourScale(
        edge.weights[scaleInfo.edgeColourIdx]);
    };

    scaleInfo.hltPathColour = function(path) {
      return scaleInfo.hltEdgeColourScale(
        path.edge.weights[scaleInfo.edgeColourIdx]);
    };
   
    scaleInfo.edgeWidth = function(edge) {
      return scaleInfo.edgeWidthScale(
        edge.weights[scaleInfo.edgeWidthIdx]);
    };

    scaleInfo.pathWidth = function(path) {
      return scaleInfo.edgeWidthScale(
        path.edge.weights[scaleInfo.edgeWidthIdx]);
    };
  }

  /*
   * Flattens the dendrogram tree for the given network 
   * (see the makeNetworkDendrogramTree function below), 
   * such that it contains at most maxClusters clusters. 
   * This function basically performs the same job as 
   * the MATLAB cluster function, e.g.:
   *
   *   > cluster(linkages, 'maxclust', maxClusters)
   */
  function flattenDendrogramTree(network, maxClusters) {

    // Returns a list of tree nodes which contain leaf 
    // nodes - the current 'clusters' in the tree.
    function getClusters() {

      var allClusts  = network.nodes.map(function(node) {return node.parent;});
      var uniqClusts = [];

      for (var i = 0; i < allClusts.length; i++) {
        if (uniqClusts.indexOf(allClusts[i]) > -1) continue;
        uniqClusts.push(allClusts[i]);
      }

      return uniqClusts;
    }

    // Iterate through the list of clusters, 
    // merging them  one by one, until we are 
    // left with (at most) maxClusters.
    var clusters = getClusters();

    while (clusters.length > maxClusters) {

      // Identify the cluster with the minimum 
      // distance between its children
      var distances = clusters.map(function(clust) {

        // the root node has no parent
        if (clust.parent) return clust.parent.distance;
        else              return Number.MAX_VALUE;
      });
      var minIdx    = distances.indexOf(d3.min(distances));

      var clust         = clusters[minIdx];
      var parent        = clust.parent;
      var children      = clust.children;
      var clustChildIdx = parent.children.indexOf(clust);
      var clustTreeIdx  = network.treeNodes.indexOf(clust);
      
      // Squeeze that cluster node out of the 
      // tree, by attaching its children to its 
      // parent and vice versa.
      parent .children .splice(clustChildIdx, 1);
      network.treeNodes.splice(clustTreeIdx,  1);

      children.forEach(function(child) {

        child.parent = parent;
        parent.children.push(child);
      });

      // Update the cluster list
      clusters = getClusters();
    }
  }

  /*
   * Given a network (see the createNetwork function), and the 
   * output of a call to the MATLAB linkage function which 
   * describes the dendrogram of clusters of the network 
   * nodes, this function creates a list of 'dummy' nodes 
   * which represent the dendrogram tree. This list is added 
   * as an attribute called 'treeNodes' of the provided 
   * network.
   */
  function makeNetworkDendrogramTree(network, linkages) {

    var numNodes  = network.nodes.length;
    var treeNodes = [];

    // Create a dummy leaf node for every node in the network
    var leafNodes = network.nodes.map(function(node, i) {
      var leafNode      = {};
      leafNode.index    = numNodes + linkages.length + i;
      leafNode.children = [node];
      node.parent       = leafNode;

      return leafNode;
    });

    for (var i = 0; i < linkages.length; i++) {
      var treeNode = {};
      var leftIdx  = linkages[i][0];
      var rightIdx = linkages[i][1];
      var left;
      var right;

      if (leftIdx  > numNodes) left  = treeNodes[leftIdx  - 1 - numNodes];
      else                     left  = leafNodes[leftIdx  - 1];
      if (rightIdx > numNodes) right = treeNodes[rightIdx - 1 - numNodes];
      else                     right = leafNodes[rightIdx - 1];

      left .parent = treeNode;
      right.parent = treeNode;

      treeNode.children = [left, right];
      treeNode.distance = linkages[i][2];
      treeNode.index    = i + numNodes;

      treeNodes.push(treeNode);
    }

    network.treeNodes = leafNodes.concat(treeNodes);
  }

  /*
   * Extracts and returns a sub-matrix from the given
   * parent matrix, containing the data at the indices
   * in the specified index array.
   */
  function extractSubMatrix(matrix, indices) {
    var submat = [];

    for (var i = 0; i < indices.length; i++) {

      var row = [];
      for (var j = 0; j < indices.length; j++) {

        row.push(matrix[indices[i]][indices[j]]);
      }
      submat.push(row);
    }

    return submat;
  }

  /*
   * Extracts and returns a subnetwork from the given network, 
   * consisting of the node at the specified index, all of the 
   * neighbours of that node, and all of the edges between 
   * them.
   */
  function extractSubNetwork(network, rootIdx) {

    var oldRoot  = network.nodes[rootIdx];

    // Create a list of node indices, in the parent 
    // network, of all nodes to be included in the 
    // subnetwork
    var nodeIdxs = [rootIdx];

    for (var i = 0; i < oldRoot.neighbours.length; i++) {
      nodeIdxs.push(oldRoot.neighbours[i].index);
    }
    nodeIdxs.sort(function(a,b){return a-b;});

    // Create a bunch of sub-matrices containing 
    // the data for the above list of nodes
    var subMatrices = network.matrices.map(
      function(matrix) {return extractSubMatrix(matrix, nodeIdxs);});

    // create a bunch of node data arrays 
    // from the original network node data
    var subNodeData = network.nodeData.map(function(array) {
      return nodeIdxs.map(function(idx) {
        return array[idx];
      });
    });

    var subnet = createNetwork(
      subMatrices, 
      network.matrixLabels, 
      subNodeData,
      network.nodeDataLabels,
      null,
      network.thumbUrl,
      network.thresholdFunc,
      network.thresholdValues,
      network.thresholdValueLabels,
      network.thresholdIdx,
      1);

    // Fix node names and thumbnails, and add 
    // indices for each subnetwork node back 
    // to the corresponding parent network node
    var zerofmt = d3.format("04d");
    for (var i = 0; i < subnet.nodes.length; i++) {

      var node = subnet.nodes[i];

      node.name         = network.nodes[nodeIdxs[i]].name;
      node.fullNetIndex = network.nodes[nodeIdxs[i]].index;

      if (subnet.thumbUrl !== null) {
        var imgurl = network.thumbUrl + "/" + zerofmt(nodeIdxs[i]) + ".png";
        node.thumbnail = imgurl;
      }
    }

    // Create a dummy dendrogram with a single cluster
    setNumClusters(subnet, 1);
      
    // save a reference to the parent network?
    // subnet.parentNetwork = network;

    return subnet;
  }

  /*
   * Creates a tree representing the dendrogram specified 
   * in the linkage data provided when the network was loaded, 
   * and flattens the tree so that it contains (at most) the 
   * specified number of clusters. If there was no linkage 
   * data specified when the network was loaded, this function 
   * does nothing.
   */
  function setNumClusters(network, numClusts) {

    if (network.linkage === null) {
          
      // Create a dummy dendrogram with a single cluster
      var root = {};
      root.index    = network.nodes.length;
      root.children = network.nodes;
      network.nodes.forEach(function(node) {node.parent = root;});
      network.treeNodes = [root];
      return;
    }

    // generate a tree of dummy nodes from 
    // the dendrogram in the linkages data
    makeNetworkDendrogramTree(network, network.linkage);

    // flatten the tree to the specified number of clusters
    flattenDendrogramTree(network, numClusts);
    network.numClusters = numClusts;
  }

  /*
   * Creates a list of edges for the given network by calling 
   * the 'thresFunc' function provided when the network was 
   * loaded. The network edges are defined by the matrix at 
   * network.matrices[network.thresholdIdx].  The list of 
   * values in all matrices (including the one just mentioned) 
   * for a given edge is added as an attribute called 'weight'
   * on that edge.
   */
  function thresholdNetwork(network) {

    var matrix   = network.matrices[network.thresholdIdx];
    var numNodes = network.nodes.length;

    // Create a list of edges. At the same time, we'll 
    // figure out the real and absolute max/min values 
    // for each weight matrix across all edges, so they 
    // can be used to scale edge colour/width/etc properly.
    network.edges     = [];
    var matrixMins    = [];
    var matrixMaxs    = [];
    var matrixAbsMins = [];
    var matrixAbsMaxs = [];

    // threshold the matrix. It is assumed that the 
    // provided threshold function behaves nicely
    // by thresholding a copy of the matrix, not 
    // the matrix itself.
    matrix = network.thresholdFunc(matrix, network.thresholdValues);
    
    // initialise min/max arrays
    for (var i = 0; i < network.matrices.length; i++) {
      matrixMins   .push( Number.MAX_VALUE);
      matrixMaxs   .push(-Number.MAX_VALUE);
      matrixAbsMins.push( Number.MAX_VALUE);
      matrixAbsMaxs.push(-Number.MAX_VALUE);
    }

    // initialise node neighbour/edge arrays
    for (var i = 0; i < numNodes; i++) {
      network.nodes[i].edges      = [];
      network.nodes[i].neighbours = [];
    }

    // Currently only undirected 
    // networks are supported
    for (var i = 0; i < numNodes; i++) {
      for (var j = i+1; j < numNodes; j++) {

        // NaN values in the matrix
        // are not added as edges
        if (isNaN(matrix[i][j])) continue;

        var edge     = {};
        edge.i       = network.nodes[i];
        edge.j       = network.nodes[j];
        edge.weights = network.matrices.map(function(mat) {return mat[i][j];});

        // d3.layout.bundle and d3.layout.force require two 
        // attributes, 'source' and 'target', so we add them 
        // here purely for convenience.
        edge.source  = edge.i;
        edge.target  = edge.j;

        network.edges.push(edge);
        network.nodes[i].neighbours.push(network.nodes[j]);
        network.nodes[j].neighbours.push(network.nodes[i]);
        network.nodes[i].edges     .push(edge);
        network.nodes[j].edges     .push(edge);

        // update weight mins/maxs
        for (var k = 0; k < edge.weights.length; k++) {

          var w  =          edge.weights[k];
          var aw = Math.abs(edge.weights[k]);

          if (w  > matrixMaxs[k])    matrixMaxs[k]    = w;
          if (w  < matrixMins[k])    matrixMins[k]    = w;
          if (aw > matrixAbsMaxs[k]) matrixAbsMaxs[k] = aw;
          if (aw < matrixAbsMins[k]) matrixAbsMins[k] = aw;
        }
      }
    }

    network.matrixMins    = matrixMins;
    network.matrixMaxs    = matrixMaxs;
    network.matrixAbsMins = matrixAbsMins;
    network.matrixAbsMaxs = matrixAbsMaxs;
  }

  /*
   * Creates a network from the given data.
   */
  function createNetwork(
    matrices,
    matrixLabels,
    nodeData,
    nodeDataLabels,
    linkage,
    thumbUrl,
    thresholdFunc,
    thresholdValues,
    thresholdValueLabels,
    thresholdIdx,
    numClusters) {

    var network  = {};
    var nodes    = [];
    var numNodes = matrices[0].length;
    var zerofmt  = d3.format("04d");

    // Create a list of nodes
    for (var i = 0; i < numNodes; i++) {

      var node = {};

      // Node name is 1-indexed
      node.index      = i;
      node.name       = "" + (i+1);
      node.nodeData   = nodeData.map(function(array) {return array[i];});

      // Attach a thumbnail URL to 
      // every node in the network
      if (thumbUrl !== null) {
        var imgUrl = thumbUrl + "/" + zerofmt(i) + ".png";
        node.thumbnail = imgUrl;
      }
      else {
        node.thumbnail = null;
      }

      nodes.push(node);
    }

    network.nodes                = nodes;
    network.nodeData             = nodeData;
    network.nodeDataLabels       = nodeDataLabels;
    network.matrices             = matrices;
    network.matrixLabels         = matrixLabels;
    network.linkage              = linkage;
    network.thumbUrl             = thumbUrl;
    network.thresholdFunc        = thresholdFunc;
    network.thresholdValues      = thresholdValues;
    network.thresholdValueLabels = thresholdValueLabels;
    network.thresholdIdx         = thresholdIdx;
    network.numClusters          = numClusters;

    // create the network edges
    thresholdNetwork(network);

    // Create a dendrogram, and flatten it 
    // to the specified number of clusters.
    // This will do nothing if this network
    // has no linkage data.
    setNumClusters(network, numClusters);

    // create scale information for 
    // colouring/scaling nodes and edges
    var scaleInfo = {};
    scaleInfo.edgeWidthIdx  = thresholdIdx;
    scaleInfo.edgeColourIdx = thresholdIdx;
    scaleInfo.nodeColourIdx = 0;

    genColourScales(network, scaleInfo);
    network.scaleInfo = scaleInfo;

    // console.log(network);

    return network;
  }

  /* 
   * Sets the matrix data used to scale edge widths
   * to the matrix at the specified index.
   */
  function setEdgeWidthIdx(network, idx) {

    if (idx < 0 || idx >= network.matrices.length) {
      throw "Matrix index out of range.";
    } 

    network.scaleInfo.edgeWidthIdx = idx;
    genColourScales(network, network.scaleInfo);
  }

  /* 
   * Sets the matrix data used to colour edges
   * to the matrix at the specified index.
   */
  function setEdgeColourIdx(network, idx) {

    if (idx < 0 || idx >= network.matrices.length) {
      throw "Matrix index out of range.";
    } 

    network.scaleInfo.edgeColourIdx = idx;
    genColourScales(network, network.scaleInfo);
  }

  /* 
   * Sets the node data used to colour nodes 
   * to the node data at the specified data index.
   */
  function setNodeColourIdx(network, idx) {
    if (idx < 0 || idx >= network.nodeDataLabels.length) {
      throw "Node data index out of range."
    }
    network.scaleInfo.nodeColourIdx = idx;
    genColourScales(network, network.scaleInfo);
  }

  /*
   * Sets the matrix used to threshold the network to the 
   * matrix at the specified index, and re-thresholds the 
   * network.
   */
  function setThresholdIdx(network, idx) {

    if (idx < 0 || idx >= network.matrices.length) {
      throw "Matrix index out of range.";
    } 

    network.thresholdIdx = idx;

    // this forces re-thresholding, and all 
    // the other stuff that needs to be done 
    setThresholdValue(network, 0, network.thresholdValues[0]);
  }

  /*
   * Sets the value for the threshold function argument at 
   * the given index, and re-thresholds the network.
   */
  function setThresholdValue(network, idx, value) {

    if (idx < 0 || idx >= network.thresholdValues.length) {
      throw "Threshold value index out of range.";
    }

    network.thresholdValues[idx] = value;
    thresholdNetwork(network);

    // force recreation of dendrogram and of colour scales
    setNumClusters(  network, network.numClusters);
    genColourScales( network, network.scaleInfo);
  }

  /*
   * The loadNetwork function (below) asynchronously loads
   * all of the data required to create a network. When
   * all that data is loaded, this function is called. 
   * This function parses the data, passes it all to the 
   * createNetwork function (above), and then passes 
   * the resulting network to the onLoadFunc callback
   * function which was passed to loadNetwork.
   */
  function onDataLoad(error, args) {

    if (error !== null) {
      throw error;
    }

    var stdArgs        = args[0];
    var nodeDataLabels = stdArgs.nodeDataLabels;
    var matrixLabels   = stdArgs.matrixLabels;
    var thumbUrl       = stdArgs.thumbnails;
    var thresFunc      = stdArgs.thresFunc;
    var thresVals      = stdArgs.thresVals;
    var thresLabels    = stdArgs.thresLabels;
    var thresholdIdx   = stdArgs.thresholdIdx;
    var numClusters    = stdArgs.numClusters;
    var onLoadFunc     = stdArgs.onLoadFunc;
    var linkage        = args[1];

    var numNodeData = nodeDataLabels.length;
    var numMatrices = matrixLabels  .length;

    var nodeData = args.slice(2,               2 + numNodeData);
    var matrices = args.slice(2 + numNodeData, 2 + numNodeData + numMatrices);

    if (linkage !== null) 
      linkage = parseTextMatrix(linkage);
    
    matrices = matrices.map(parseTextMatrix);
    nodeData = nodeData.map(parseTextMatrix);

    // node data should be 1D arrays
    nodeData = nodeData.map(function(array) {return array[0];});

    // check all data arrays to ensure 
    // they are of compatible lengths
    var numNodes = matrices[0].length;

    matrices.forEach(function(matrix, i) {
      var errorMsg =  "Matrix " + matrixLabels[i] + " has invalid size ";
      
      // number of rows
      if (matrix.length !== numNodes) {
        throw errorMsg + "(num rows: " + matrix.length + ")";
      }

      // number of columns in each row
      matrix.forEach(function(row) {
        if (row.length !== numNodes) {
          throw errorMsg + "(column length " + row.length + ")";
        }
      });
    });

    // node data arrays
    nodeData.forEach(function(array, i) {
      if (array.length !== numNodes) {
        throw "Node data array " + nodeDataLabels[i] + 
              " has invalid length (" + array.length + ")";
      }
    });

    network = createNetwork(
      matrices, 
      matrixLabels, 
      nodeData,
      nodeDataLabels, 
      linkage, 
      thumbUrl,
      thresFunc,
      thresVals,
      thresLabels,
      thresholdIdx,
      numClusters);

    onLoadFunc(network);
  }

  /*
   * Loads all of the network data provided in the given args
   * object. When the network data is loaded, a network is created
   * and passed to the onLoadFunc callback function.
   * 
   * The args object should have the following properties:
   *
   *   - matrices:       Required. A list of URLS pointing to 
   *                     connectivity matrices.
   *
   *   - matrixLabels:   Optional. A list of labels for each of 
   *                     the above matrices.
   * 
   *   - nodeData:       Optional. A list of URLS pointing to 
   *                     1D arrays of numerical data, to be 
   *                     associated with the nodes in the network.
   *
   *   - nodeDataLabls:  Optional. A list of labels for each of 
   *                     the above arrays.
   *
   *   - linkage:        Optional. A N*3 array of data describing
   *                     the dendrogram for the network - the output
   *                     of a call to the MATLAB linkage function.
   * 
   *   - thumbnails:     Optional. A URL pointing to a folder in 
   *                     which thumbnails for each node may be 
   *                     found. Thumbnail file names must currently 
   *                     be named according to the format "%04d.png",
   *                     where "%04d" is the zero-indexed node index
   *                     in the network, padded to four characters.
   *                     
   *   - thresFunc:      Required. A function which accepts two 
   *                     parameters - a connectivity matrix, and a 
   *                     list of parameters (thresVals, see below).
   *                     This function should create and return a 
   *                     thresholded copy of the provided matrix - 
   *                     this thresholded matrix is used to define
   *                     network edges. Currently, all accepted 
   *                     threshold  values must be between 0.0 and 
   *                     1.0.
   *
   *   - thresVals:      Optional. List of parameters to be passed
   *                     to the thresFunc. Must currently be between
   *                     0.0 and 1.0.
   * 
   *   - thresLabels:    Optional. List of labels for the above
   *                     threshold values.
   * 
   *   - thresholdIdx:   Optional. Initial index of the connectivity 
   *                     matrix used to define the network edges.
   * 
   *   - numClusters:    Optional. Initial number of clusters to 
   *                     flatten the network dendrogram tree to.
   */
  function loadNetwork(args, onLoadFunc) {

    var a = args;

    a.onLoadFunc = onLoadFunc;

    if (a.matrices === undefined) 
      throw "A list of matrices must be specified";

    if (a.matrices.length === 0) 
      throw "At least one matrix is required";

    if (a.thresFunc === undefined) 
      throw "A thresFunc must be specified";

    if (a.matrixLabels === undefined) 
      a.matrixLabels = a.matrices.slice(0);
    
    if (a.nodeData === undefined) 
      a.nodeData = [];

    if (a.nodeDataLabels === undefined) 
      a.nodeDataLabels = a.nodeData.map(function(nd,i){ return "" + i;});


    if (a.thresVals === undefined) 
      a.thresVals = [];

    if (a.thresLabels === undefined) 
      a.thresLabels = a.thresVals.map(function(tv,i){ return "" + i;});

    if (a.linkage      === undefined) a.linkage      = null;
    if (a.thumbnails   === undefined) a.thumbnails   = null;
    if (a.thresholdIdx === undefined) a.thresholdIdx = 0;
    if (a.numClusters  === undefined) a.numClusters  = 1;

    if (a.matrices.length !== a.matrixLabels.length) 
      throw "Matrix URL and label lengths do not match";

    if (a.nodeData.length !== a.nodeDataLabels.length) 
      throw "Node data URL and label lengths do not match";

    if (a.thresVals.length !== a.thresLabels.length) 
      throw "Threshold value and label lengths do not match";

    // The qId function is an identity function 
    // which may be used to pass standard 
    // arguments (i.e. arguments which are not 
    // the result of an asychronous load) to the 
    // await/awaitAll functions.
    function qId(arg, cb) {cb(null, arg);}

    // Load all of the network data, and 
    // pass it to the onDataLoad function. 
    var q = queue();

    // standard arguments
    q = q.defer(qId, a);
    
    // linkage data
    if (a.linkage !== null) q = q.defer(d3.text, a.linkage);
    else                    q = q.defer(qId,     a.linkage);

    // node data
    a.nodeData.forEach(function(url) {
      q = q.defer(d3.text, url);
    });

    // matrix data
    a.matrices.forEach(function(url) {
      q = q.defer(d3.text, url);
    });

    // load all the things!
    q.awaitAll(onDataLoad);
  }

  /*
   * Uses d3.dsv to turn a string containing 
   * numerical matrix data into a 2D array.
   */
  function parseTextMatrix(matrixText) { 

    // create a parser for space delimited text
    var parser = d3.dsv(" ", "text/plain");
      
    // parse the text data, converting each value to 
    // a float and ignoring any extraneous whitespace
    // around or between values.
    var matrix = parser.parseRows(matrixText, function(row) {
      row = row.filter(function(value) {return value != ""; } );
      row = row.map(   function(value) {return parseFloat(value);});
      return row;
    });

    return matrix;
  }


  var netdata               = {};
  netdata.loadNetwork       = loadNetwork;
  netdata.extractSubNetwork = extractSubNetwork;
  netdata.setNumClusters    = setNumClusters;
  netdata.setEdgeWidthIdx   = setEdgeWidthIdx;
  netdata.setEdgeColourIdx  = setEdgeColourIdx;
  netdata.setNodeColourIdx  = setNodeColourIdx;
  netdata.setThresholdIdx   = setThresholdIdx;
  netdata.setThresholdValue = setThresholdValue;
  return netdata;
});
