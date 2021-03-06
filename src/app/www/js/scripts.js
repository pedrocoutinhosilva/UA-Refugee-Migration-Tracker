let updateURLParamether = function(parameter, value) {
  // Construct URLSearchParams object instance from current URL querystring.
  var queryParams = new URLSearchParams(window.location.search);

  // Set new or modify existing parameter value.
  queryParams.set(parameter, value);

  // Replace current querystring with the new one.
  history.replaceState(null, null, "?"+queryParams.toString());
}


let getCarState = function(entry) {
  if (isNaN(entry)) {
    return("none")
  }

  if (entry > 0 && entry <= 2) {
    return("yellow")
  }

  if (entry > 2) {
    return("red")
  }

  return("green")
}

let getPedestrianState = function(entry) {
  if (isNaN(entry)) {
    return("none")
  }

  if (entry > 0 && entry <= 1) {
    return("yellow")
  }
  if (entry > 1) {
    return("red")
  }

  return("green")
}

let toggleHelp = function(state) {
  $(".map-controls-help").toggleClass("active", state);
}

$( document ).ready(function() {
  // Map events
  $('#mymap').on('mouseenter', '.country-shape', function() {
    $( this ).addClass('highlighted');
  });

  $('#mymap').on('mouseleave', '.country-shape', function() {
    $( this ).removeClass('highlighted');
  });

  const delta = 6;
  let startX;
  let startY;

  document.getElementById('mymap').addEventListener('mousedown', function (event) {
    toggleHelp(false);
  });
  document.getElementById('mymap').addEventListener('touch', function (event) {
    toggleHelp(false);
  });

  document.getElementById('mymap').addEventListener('mousedown', function (event) {
    startX = event.pageX;
    startY = event.pageY;
  });

  document.getElementById('mymap').addEventListener('mouseup', function (event) {
    const diffX = Math.abs(event.pageX - startX);
    const diffY = Math.abs(event.pageY - startY);

    if (diffX < delta && diffY < delta) {
      if (!$(event.target.parentElement).is('.leaflet-marker-pane .custom-asset-marker')) {
        togglePopup(false);
      }

      if ($(event.target.parentElement).is('.leaflet-marker-pane .custom-asset-marker')) {

        if ($(event.target.parentElement).hasClass("selected")) {
          $(event.target.parentElement).removeClass("selected");

          togglePopup(false);
        } else {
          selectMarker(event.target.parentElement);

          let data_id = HTMLWidgets
            .getInstance(document.getElementById("mymap"))
            .getMap()
            ._targets[event.target.parentElement._leaflet_id].options.layerId
            .split("_")

          let point_data = station_data.checkpoints[data_id[0]][parseInt(data_id[1]) - 1]

          document.getElementById("checkpointInnerTitle").innerHTML = point_data.inner_border_name;
          document.getElementById("checkpointOuterTitle").innerHTML = point_data.outer_border_name;

          let car_state = getCarState(parseFloat(point_data.car_queue_hours));
          let pedestrian_state = getPedestrianState(parseFloat(point_data.foot_queue_hours));

          document.getElementById("carKM").innerHTML = function() {
            switch (car_state) {
              case "none": return(`<span></span><span>Not available</span>`)
                break;
              default: return(`<span>${parseFloat(point_data.car_queue_km)}</span><span> KM</span>`)
            }
          }();

          document.getElementById("carHours").innerHTML = function() {
            switch (car_state) {
              case "none": return(`<span></span><span>Not available</span>`)
                break;
              default: return(`<span>${parseFloat(point_data.car_queue_hours)}</span><span> Hours</span>`)
            }
          }();

          document.getElementById("pedestrianHours").innerHTML = function() {
            switch (pedestrian_state) {
              case "none": return(`<span></span><span>Not available</span>`)
                break;
              default: return(`<span>${parseFloat(point_data.foot_queue_hours)}</span><span> Hours</span>`)
            }
          }();

          document.getElementById("pedestrianNumber").innerHTML = function() {
            switch (pedestrian_state) {
              case "none": return(`<span></span><span>Not available</span>`)
                break;
              default: return(`<span>${parseFloat(point_data.foot_queue_units)}</span><span> People</span>`)
            }
          }();

          document.getElementById("lastUpdate").innerHTML = `
            <span>${point_data.last_update_day}</span>
            <span>${point_data.last_update_hour}</span>
          `;

          document.getElementById("telegramChats").innerHTML = `
            <a target = "_target" href = "${point_data.telegram}">${point_data.telegram}</a>
          `;

          document.getElementById("googleLink").innerHTML = `
            <a target = "_target" href = "https://www.google.com/maps/search/?api=1&query=${point_data.lat},${point_data.lng}">Coordinates: ${point_data.lat}, ${point_data.lng}</a>
          `;

          togglePopupClass({
            car: car_state,
            pedestrian: pedestrian_state
          });
          togglePopup(true);
        }
      }
    }
  });

  // Toggle overlays
  $('#overlayLegendGrid').on('click', function(event) {
    $('#overlayLegendGrid').removeClass("active");
  });
  $('#overlayLegendGrid').on('click', ".control-wrapper", function(event) {
    event.stopPropagation();
  });
});

let resetZoom = function() {
  let zoomBox = $(".legend-control.country-focus").hasClass("active")
    ? station_data.map_bounds
    : station_data.map_bounds_focus

  HTMLWidgets
    .getInstance(document.getElementById("mymap"))
    .getMap().fitBounds(zoomBox);
}

// Map controls
let toggleTiles = function(target) {
  $(".leaflet-pane.leaflet-tile-pane").toggleClass("active");
  $(target).toggleClass("active");
}

let toggleCities = function(target) {
  $(".city-control-marker").toggleClass("disabled");
  $(target).toggleClass("active");
}

let toggleCountryShapes = function(target) {
  $(".country-shape.bordering").toggleClass("disabled");
  $(".country-shape.ukraine").toggleClass("focused");
  $(target).toggleClass("active");

  resetZoom();
}

let toggleCountries = function(target) {
  $(".leaflet-tooltip.country-refugees").toggleClass("disabled");
  $(target).toggleClass("active");
}

let toggleBorders = function(target) {
  $(".leaflet-marker-pane .custom-asset-marker").toggleClass("disabled");
  $(target).toggleClass("active");
}

let toggleInternal = function(target) {
  let state = [
    {
      target: "border-points",
      state: false
    },
    {
      target: "refugee-numbers",
      state: false
    },
    {
      target: "contested-cities",
      state: true
    },
    {
      target: "country-focus",
      state: false
    },
    {
      target: "map-tiles",
      state: true
    }
  ]

  state.map(function(entry) {
    if (entry.state) {
      if (!$(`.legend-control.${entry.target}`).hasClass("active")) {
        $(`.legend-control.${entry.target}`).click()
      }
    } else {
      if ($(`.legend-control.${entry.target}`).hasClass("active")) {
        $(`.legend-control.${entry.target}`).click()
      }
    }
  });

  togglePopup(false);
  resetZoom();
  updateURLParamether("v", "city");
}

let toggleExternal = function(target) {
  let state = [
    {
      target: "border-points",
      state: true
    },
    {
      target: "refugee-numbers",
      state: true
    },
    {
      target: "contested-cities",
      state: false
    },
    {
      target: "country-focus",
      state: true
    },
    {
      target: "map-tiles",
      state: false
    }
  ]

  state.map(function(entry) {
    if (entry.state) {
      if (!$(`.legend-control.${entry.target}`).hasClass("active")) {
        $(`.legend-control.${entry.target}`).click()
      }
    } else {
      if ($(`.legend-control.${entry.target}`).hasClass("active")) {
        $(`.legend-control.${entry.target}`).click()
      }
    }
  });

  resetZoom();
  updateURLParamether("v", "border");
}

let selectMarker = function(target) {
  $(".leaflet-marker-pane .custom-asset-marker").removeClass("selected");
  $(target).addClass("selected");
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
