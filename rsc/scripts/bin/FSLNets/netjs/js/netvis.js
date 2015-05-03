/*
 * Display the dendrogram and connectivity of a 
 * of a network using D3.js.
 * 
 * Author: Paul McCarthy <pauldmccarthy@gmail.com>
 *
 * Citations: 
 *   - http://d3js.org/
 *   - http://bl.ocks.org/mbostock/7607999
 */
define(["lib/d3"], function(d3) {

  /* 
   * Various per-network constants for configuring how 
   * nodes, labels, thumbnails, and edges are displayed
   * normally (DEF), when highlighted (HLT), and when 
   * selected (SEL).
   */
  var visDefaults = {};
  visDefaults.DEF_LABEL_SIZE   = 10;
  visDefaults.HLT_LABEL_SIZE   = 10;
  visDefaults.SEL_LABEL_SIZE   = 16;
  visDefaults.DEF_LABEL_WEIGHT = "normal";
  visDefaults.HLT_LABEL_WEIGHT = "bold";
  visDefaults.SEL_LABEL_WEIGHT = "bold";
  visDefaults.DEF_LABEL_FONT   = "sans";
  visDefaults.HLT_LABEL_FONT   = "sans";
  visDefaults.SEL_LABEL_FONT   = "sans";

  visDefaults.DEF_THUMB_VISIBILITY = "hidden";
  visDefaults.HLT_THUMB_VISIBILITY = "visible";
  visDefaults.SEL_THUMB_VISIBILITY = "visible";
  visDefaults.DEF_THUMB_WIDTH  = 91 /2.5;
  visDefaults.HLT_THUMB_WIDTH  = 91 /2.5;
  visDefaults.SEL_THUMB_WIDTH  = 91 /2.0;
  visDefaults.DEF_THUMB_HEIGHT = 109/2.5;
  visDefaults.HLT_THUMB_HEIGHT = 109/2.5;
  visDefaults.SEL_THUMB_HEIGHT = 109/2.0;

  // edge width and colour are scaled 
  // according to edge weights. Also,
  // a default edge opacity of less 
  // than 1.0 will result in a huge 
  // performance hit for large networks.
  visDefaults.DEF_EDGE_COLOUR  = "default";
  visDefaults.HLT_EDGE_COLOUR  = "highlight";
  visDefaults.DEF_EDGE_WIDTH   = 1;
  visDefaults.HLT_EDGE_WIDTH   = "scale";
  visDefaults.DEF_EDGE_OPACITY = 1.0;
  visDefaults.HLT_EDGE_OPACITY = 0.7;

  visDefaults.DEF_NODE_SIZE    = 3;
  visDefaults.HLT_NODE_SIZE    = 3;
  visDefaults.SEL_NODE_SIZE    = 5;
  visDefaults.DEF_NODE_OPACITY = 0.5;
  visDefaults.HLT_NODE_OPACITY = 1.0;
  visDefaults.SEL_NODE_OPACITY = 1.0;

  /*
   * Draw the nodes of the network. It is assumed that the network
   * has the following D3 selections as attributes (which are 
   * created and attached to the network in the displayNetwork 
   * function):
   *
   *   - network.svgNodes:      Place to draw circles representing nodes
   *   - network.svgNodeLabels: Place to draw node labels
   *   - network.svgThumbnails: Place to draw node thumbnails
   *
   * And that the network also has a 'treeNodes' attribute, containing 
   * node in the dendrogram tree (see the makeNetworkDendrogramTree 
   * function).
   */
  function drawNodes(network) {

    var svg    = network.display.svg;
    var radius = network.display.radius;

    // We use the D3 cluster layout to draw the nodes in a circle.
    // This also lays out the tree nodes (see the 
    // makeNetworkDendrogramTree function) which represent the 
    // network dendrogram. These nodes are not displayed, but their
    // locations are used to determine the path splines used to
    // display edges (see the drawEdges function).
    var clusterLayout  = d3.layout.cluster().size([360, radius-110]);
    var rootNode       = network.treeNodes[network.treeNodes.length - 1];
    var clusteredNodes = clusterLayout.nodes(rootNode);
    var leafNodes      = network.nodes;

    // Position nodes in a big circle.
    function positionNode(node) {
      return "rotate("    + (node.x - 90) + ")"   + 
             "translate(" + (node.y)      + ",0)" + 
             (node.x < 180 ? "" : "rotate(180)"); 
    }

    // Position labels in a slightly bigger circle.
    function positionLabel(node) {
      return "rotate("    + (node.x - 90)   + ")"  + 
             "translate(" + (node.y + 4)  + ",0)" + 
             (node.x < 180 ? "" : "rotate(180)"); 
    }

    // Position thumbnails in an even slightly bigger 
    // circle, ensuring that they are upright.
    function positionThumbnail(node) {
      return "rotate("    + ( node.x - 90) + ")"   + 
             "translate(" + ( node.y + 40) + ",0)" + 
             "rotate("    + (-node.x + 90) + ")"   +
             "translate(-23,-28)";
    }

    // Position node names nicely.
    function anchorLabel(node) {
      return node.x < 180 ? "start" : "end"; 
    }

    // The circle, label and thumbnail for a specific node 
    // are given css class 'node-X', where X is the node 
    // index. For every neighbour of a particular node, that 
    // node is also given the css class  'nodenbr-Y', where 
    // Y is the index of the neighbour.
    function nodeClasses(node) {

      var classes = ["node-" + node.index];

      node.neighbours.forEach(function(nbr) {
        classes.push("nodenbr-" + nbr.index);
      });

      return classes.join(" ");
    }

    // Draw the nodes
    network.display.svgNodes
      .selectAll("circle")
      .data(network.nodes)
      .enter()
      .append("circle")
      .attr("class",     nodeClasses)
      .attr("transform", positionNode)
      .attr("opacity",   network.display.DEF_NODE_OPACITY)
      .attr("r",         network.display.DEF_NODE_SIZE)
      .attr("fill",      network.scaleInfo.nodeColour);
      
    // Draw the node labels
    network.display.svgNodeLabels
      .selectAll("text")
      .data(network.nodes)
      .enter()
      .append("text")
      .attr("class",        nodeClasses)
      .attr("dy",          ".31em")
      .attr("opacity",      network.display.DEF_NODE_OPACITY)
      .attr("font-family",  network.display.DEF_LABEL_FONT)
      .attr("font-weight",  network.display.DEF_LABEL_WEIGHT)
      .attr("font-size",    network.display.DEF_LABEL_SIZE)
      .attr("fill",         network.scaleInfo.nodeColour)
      .attr("transform",    positionLabel)
      .style("text-anchor", anchorLabel)
      .text(function(node) {return node.name; });

    // Draw the node thumbnails 
    network.display.svgThumbnails
      .selectAll("image")
      .data(network.nodes)
      .enter()
      .append("image")
      .attr("class",       nodeClasses)
      .attr("transform",   positionThumbnail)
      .attr("visibility",  network.display.DEF_THUMB_VISIBILITY)
      .attr("width",       network.display.DEF_THUMB_WIDTH)
      .attr("height",      network.display.DEF_THUMB_HEIGHT)
      .attr("xlink:href",  function(node) {return node.thumbnail;});
  }

  /*
   * Draw the edges of the given network. An edge between two nodes
   * is drawn as a spline path which wiggles its way from the first 
   * node, through the dendrogram tree up to the first common 
   * ancester of the two nodes, and then back down to the second 
   * node. Most of the hard work is done by the d3.layout.bundle 
   * function.
   */
  function drawEdges(network) {

    var svg    = network.display.svg;
    var radius = network.display.radius;

    // For drawing network edges as splines
    var bundle = d3.layout.bundle();
    var line   = d3.svg.line.radial()
      .interpolate("bundle")
      .tension(.85)
      .radius(function(node) { return node.y - 8; })
      .angle( function(node) { return node.x / 180 * Math.PI; });

     // Each svg path element is given two classes - 'edge-X' 
     // and 'edge-Y', where X and Y are the edge endpoints
    function edgeClasses(path) {
      end = path.length - 1;
      classes = ["edge-" + path[0].index, "edge-" + path[end].index];
      return classes.join(" ");
    }

    // Each edge is also given an id 'edge-X-Y', where 
    // X and Y are the edge endpoints (and X < Y).
    function edgeId(path) {
      end = path.length - 1;
      idxs = [path[0].index, path[end].index];
      idxs.sort(function(a, b){return a-b});
      return "edge-" + idxs[0] + "-" + idxs[1];
    }
    
    // Generate the spline paths for each edge,
    // and attach each edge as an attribute of
    // its path, and vice versa, to make things
    // easier in the various callback functions
    // passed to D3 (see the configDynamics
    // function)
    var paths = bundle(network.edges);
    for (var i = 0; i < paths.length; i++) {
      paths[i].edge         = network.edges[i];
      network.edges[i].path = paths[i];
    }

    // And we'll also add the paths associated with
    // the edges of each node as an attribute of 
    // that node, again to make D3 callback functions
    // nicer.
    network.nodes.forEach(function(node) {
      node.paths = node.edges.map(function(edge) {return edge.path;});
    });

    var edgeColour = network.display.DEF_EDGE_COLOUR;
    var edgeWidth  = network.display.DEF_EDGE_WIDTH;

    if      (edgeWidth  === "scale")     
      edgeWidth  = network.scaleInfo.pathWidth;
    if      (edgeColour === "default")   
      edgeColour = network.scaleInfo.defPathColour;
    else if (edgeColour === "highlight") 
      edgeColour = network.scaleInfo.hltPathColour;

    // draw the edges
    network.display.svgEdges
      .selectAll("path")
      .data(paths)
      .enter()
      .append("path")
      .attr("id",              edgeId)
      .attr("class",           edgeClasses)
      .attr("stroke",          edgeColour)
      .attr("stroke-width",    edgeWidth)
      .attr("stroke-linecap", "round")
      .attr("fill",           "none")
      .attr("opacity",         network.display.DEF_EDGE_OPACITY)
      .attr("d",               line);
  }

  /*
   * Takes a network created by the matricesToNetowrk 
   * function (see below), and displays it in the 
   * specified networkDiv element, with nodes arranged 
   * in a big circle.
   */
  function displayNetwork(network, div, width, height) {

    var diameter = Math.min(width, height);
    var radius   = diameter / 2;

    // put an svg element inside the networkDiv
    var svg = null;
    if (!network.display || !network.display.svg) {
      svg = d3.select(div).append("svg")
        .attr("width",       width)
        .attr("height",      height)
        .style("background-color", "#fafaf0")
    }
    else {
      svg = network.display.svg;
    }

    var parentGroup = svg
      .append("g")
      .attr("id", "networkParentGroup")
      .attr("transform", "translate(" + radius + "," + radius + ")");

    // The network display consists of four types of things:
    //   - <circle> elements, one for each node
    //   - <text> elements containing the label for each node
    //   - <image> elements containing the thumbnail for each node
    //   - <path> elements, one for each edge
    //
    // In addition to this, a single div is added to the <body>,
    // which is used as a popup to display edge weights when
    // the mouse moves over an edge.
    // 

    if (!network.display) network.display = {};
    network.display.svg           = svg;
    network.display.radius        = radius;
    network.display.width         = width;
    network.display.height        = height;

    // The order of these lines defines the order in which the 
    // elements are displayed (last displayed on top)
    network.display.svgEdges      = parentGroup.append("g");
    network.display.svgThumbnails = parentGroup.append("g");
    network.display.svgNodes      = parentGroup.append("g");
    network.display.svgNodeLabels = parentGroup.append("g");

    for (var prop in visDefaults) {
      if (!network.display[prop])
        network.display[prop] = visDefaults[prop];
    }

    // Draw all of the things!
    drawNodes(network);
    drawEdges(network);
  }

  /*
   * Redraws the given network on its pre-existing svg canvas.
   */
  function redrawNetwork(network) {
    network.display.svg.select("#networkParentGroup").remove();
    displayNetwork(
      network, null, network.display.width, network.display.height);
  }

  /*
   * Deletes the SVG canvas associated with the given network.
   */
  function clearNetwork(network) {

    if (!network.display) return;
    network.display.svg.remove();
    delete network.display;
  }

  var netvis = {};
  netvis.displayNetwork = displayNetwork;
  netvis.redrawNetwork  = redrawNetwork;
  netvis.clearNetwork   = clearNetwork;
  netvis.visDefaults    = visDefaults;
  return netvis;

});
