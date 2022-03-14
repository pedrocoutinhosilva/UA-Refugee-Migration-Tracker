$( document ).ready(function() {
  // Map events
  $('#mymap').on('mouseenter', '.country-shape', function() {
    $( this ).addClass('highlighted');
  });

  $('#mymap').on('mouseleave', '.country-shape', function() {
    $( this ).removeClass('highlighted');
  });

  $('#mymap').on('click', '.leaflet-marker-pane .custom-asset-marker', function() {
    selectMarker(this);
    togglePopup(true);
  });

  // Toggle overlays
  $('#overlayLegendGrid').on('click', function(event) {
    $('#overlayLegendGrid').removeClass("active");
  });
  $('#overlayLegendGrid').on('click', ".control-wrapper", function(event) {
    event.stopPropagation();
  });
});

// Map controls
let toggleTiles = function(target) {
  $(".leaflet-pane.leaflet-tile-pane").toggleClass("active");
  $(target).toggleClass("active");
}
let toggleLoader = function(state) {
  $("#overlayLoading").addClass("disabled");
}
Shiny.addCustomMessageHandler("toggleLoader", toggleLoader);

let toggleCountries = function(target) {
  $(".leaflet-tooltip.country-refugees").toggleClass("disabled");
  $(target).toggleClass("active");
}

let toggleBorders = function(target) {
  $(".leaflet-marker-pane .custom-asset-marker").toggleClass("disabled");
  $(target).toggleClass("active");
}

let selectMarker = function(target) {
  $(".leaflet-marker-pane .custom-asset-marker").removeClass("selected");
  $(target).addClass("selected")
}

// Marker popups
let togglePopup = function(state) {
  $(".control-wrapper.popup").toggleClass("active", state);
  $("#overlayGrid").toggleClass("active", state);
  $(".app-title").toggleClass("disabled", state);

  if (!state) {
    $(".leaflet-marker-pane .custom-asset-marker").removeClass("selected");
    $("#overlayGrid").removeClass("active");
    $(".app-title").removeClass("disabled");
  }
}
Shiny.addCustomMessageHandler("togglePopup", togglePopup);

let togglePopupClass = function(state) {
  $(".control-wrapper.popup")
    .removeClass([
      "car-green",
      "car-yellow",
      "car-red",
      "car-none",
      "pedestrian-green",
      "pedestrian-yellow",
      "pedestrian-red",
      "pedestrian-none"
    ])
    .addClass([
      `pedestrian-${state.pedestrian}`,
      `car-${state.car}`
    ]);
}
Shiny.addCustomMessageHandler("togglePopupClass", togglePopupClass);
