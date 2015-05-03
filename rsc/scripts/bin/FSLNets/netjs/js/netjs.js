/*
 * Application interface for the netjs library. Exposes two functions:
 *
 *   - loadNetwork:     Given a bunch of URLs and metadata, loads 
 *                      the data at the URLs and creates a network.
 *                      from it.
 *   - displayNetwork:  Displays a network on a div.
 *
 * Author: Paul McCarthy <pauldmccarthy@gmail.com>
 */
define(
  ["netvis", "netdata", "netctrl", "netvis_dynamics"], 
  function(netvis, netdata, netctrl, dynamics) {

  function displayNetwork(
    network, 
    networkDiv, 
    subNetDiv, 
    controlDiv,
    networkWidth, 
    networkHeight,
    subNetWidth,
    subNetHeight) {

    netvis.displayNetwork(network, networkDiv, networkWidth, networkHeight);
    dynamics.configDynamics(network); 

    netctrl.createNetworkControls(
      network, controlDiv, subNetDiv, subNetWidth, subNetHeight);
  }

  var netjs = {};
  netjs.loadNetwork    = netdata.loadNetwork;
  netjs.displayNetwork = displayNetwork;

  return netjs;
});
