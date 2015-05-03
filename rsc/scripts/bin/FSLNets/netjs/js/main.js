require(["netjs", "lib/d3"], function(netjs, d3) {

  function thresholdMatrix(matrix, args) {

    var thresPerc = args[0];

    var thresMatrix = [];
    var nodeThress  = [];

    for (var i = 0; i < matrix.length; i++) {
      absVals = matrix[i].map(function(val) {return Math.abs(val);});
      nodeThress.push(d3.max(absVals) * thresPerc); 
    }

    for (var i = 0; i < matrix.length; i++) {

      thresMatrix.push([]);

      for (var j = 0; j < matrix[i].length; j++) {

        if (Math.abs(matrix[i][j]) < nodeThress[i] ||
            Math.abs(matrix[i][j]) < nodeThress[j])

          thresMatrix[i].push(Number.NaN);
        else 
          thresMatrix[i].push(matrix[i][j]);
      }
    }

    return thresMatrix;
  }

  var args            = {};
  args.matrices       = ["data/dataset1/Znet1.txt", "data/dataset1/Znet2.txt"];
  args.matrixLabels   = ["Full Correlation", "Partial"];
  args.nodeData       = ["data/dataset1/clusters.txt"];
  args.nodeDataLabels = ["Cluster number"];
  args.linkage        =  "data/dataset1/linkages.txt";
  args.thumbnails     =  "data/dataset1/melodic_IC_sum.sum";
  args.thresFunc      = thresholdMatrix;
  args.thresVals      = [0.75];
  args.thresLabels    = ["Threshold percentage"];
  args.thresholdIdx   = 0;
  args.numClusters    = 10;

  // args.matrices       = ["data/dummy/corr1.txt", "data/dummy/corr2.txt"];
  // args.matrixLabels   = ["Corr1", "Corr2"];
  // args.nodeData       = ["data/dummy/clusters.txt"];
  // args.nodeDataLabels = ["Cluster number"];
  // args.linkage        =  "data/dummy/linkages.txt";
  // args.thumbnails     =  "data/dummy/thumbnails";
  // args.thresFunc      = thresholdMatrix;
  // args.thresVals      = [0.75];
  // args.thresLabels    = ["Thres perc"];

  netjs.loadNetwork(args, function(net) {

    var w  = window.innerWidth  - 250;
    var h  = window.innerHeight - 50;
    var sz = Math.min(w/2.0, h);
    
    netjs.displayNetwork(
      net, 
      "#fullNetwork",
      "#subNetwork",
      "#networkCtrl",
      sz,sz,sz,sz);
  });
});

