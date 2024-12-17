# 1. PACKAGES
#------------

pacman::p_load(
    arcgis,
    geodata,
    sf, dots,
    tidyverse,
    elevatr, terra,
    rayshader
)

# 2. POPULATION DATA
#-------------------

url <- "https://services1.arcgis.com/ZGrptGlLV2IILABw/arcgis/rest/services/Pop_Admin1/FeatureServer/0"

data <- arcgislayers::arc_open(
    url
)

admin1_population <- arcgislayers::arc_select(
    data,
    fields = c(
        "HASC_1", "ISO2", "Population"
    ),
    where = "ISO2 = 'AT'"
) |>
sf::st_drop_geometry()

# 3. SUBNATIONAL BOUNDARIES
#--------------------------

country_admin1_sf <- geodata::gadm(
    country = "AUT",
    level = 1,
    path = getwd()
) |>
    sf::st_as_sf() |>
    sf::st_cast("MULTIPOLYGON")

# 4. MERGE BOUNDARIES AND POPULATION DATA
#----------------------------------------

crs <- "+proj=tmerc +lat_0=0 +lon_0=6 +k=1 +x_0=2500000 +y_0=0 +ellps=bessel +units=m +no_defs +type=crs"

country_admin1_population <- dplyr::left_join(
    country_admin1_sf,
    admin1_population,
    by = "HASC_1"
) |>
sf::st_transform(crs = crs)

# 5. CALCULATE DOT DENSITY
#-------------------------

population_dots <- dots::dots_points(
    shp = country_admin1_population,
    col = "Population",
    engine = engine_sf_random,
    divisor = 50000
)

# 6. 2D DOT DENSITY MAP
#----------------------

p <- ggplot() +
geom_sf(
    country_admin1_population,
    fill = "#153041",
    color = "#204863",
    linewidth = .5
) +
geom_sf(
    data = population_dots,
    color = "#ffd301",
    size = .1
) +
coord_sf(crs = crs) +
theme_void()

print(p)

# 7. DIGITAL ELEVATION MODEL
#---------------------------

dem <- elevatr::get_elev_raster(
    locations = country_admin1_sf,
    z = 7,
    clip = "locations"
)

dem_reproj <- dem |>
    terra::rast() |>
    terra::project(crs)

dem_matrix <- rayshader::raster_to_matrix(
    dem_reproj
)

# 8. RENDER BOUNDARY
#-------------------

dem_matrix |>
rayshader::height_shade(
    texture = colorRampPalette(
        "white"
    )(16)
) |>
rayshader::add_overlay(
    rayshader::generate_polygon_overlay(
        geometry = country_admin1_population,
        palette = "#153041",
        linecolor = "#3D8DBF",
        linewidth = 5,
        extent = dem_reproj,
        heightmap = dem_matrix
    ), alphalayer = 1
) |>
rayshader::plot_3d(
    dem_matrix,
    zscale = 50,
    solid = FALSE,
    shadow = TRUE,
    shadow_darkness = 1,
    windowsize = c(600, 600),
    phi = 89,
    zoom = .65,
    theta = 0
)

rayshader::render_camera(
    zoom = .75
)

# 9. RENDER POINTS
#-----------------

coords <- sf::st_coordinates(
    population_dots
)

long <- coords[, "X"]
lat <- coords[, "Y"]

altitude <- terra::extract(
    x = dem_reproj,
    y = terra::vect(
        population_dots
    ),
    fun = min,
    na.rm = TRUE
)

altitude <- altitude[, 2]

rayshader::render_points(
    lat = lat,
    long = long,
    altitude = altitude,
    extent = dem_reproj,
    heightmap = dem_matrix,
    zscale = 20,
    size = 3,
    color = "#ffd301"
)

# 10. RENDER OBJECT
#------------------

u <- "https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/4k/brown_photostudio_02_4k.hdr"

hdri_file <- basename(u)

download.file(
    url = u,
    destfile = hdri_file,
    mode = "wb"
)

rayshader::render_highquality(
    filename = "3d-dot-density-austria.png",
    preview = TRUE,
    light = FALSE,
    environment_light = hdri_file,
    intensity_env = 1,
    rotate_env = 90,
    interactive = FALSE,
    width = 4000,
    height = 4000,
    point_material = rayrender::glossy,
    point_material_args = list(
        color = "#ffd301",
        gloss = .4,
        reflectance = .1 # should be reflectance = .1
    ),
    point_radius = 3
)
