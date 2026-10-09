## Install library sits
library(sits)

## Retrieve samples
samples <- sits_from_parquet(
    file = "./samples/samples_rondonia_degrad.parquet"
)

## Select bands to match image data
samples_bands_data <- sits_select(
    data = samples,
    bands = c("B02", "B03", "B04", "B08", "B11")
)
## Train tempccn model
tcnn_model <- sits_train(
    samples = samples_bands_data,
    ml_method = sits_tempcnn()
)
saveRDS(tcnn_model, file = "./models/tcnn_model.rds")

## Retrieve data from Hugging Face
cube_012014 <- sits_from_hf(
    repo = "e-sensing/Rondonia_012014_BDC",
    type = "dataset",
    output_dir = "./data",
    multicores = 6
)
# recover local data
# skip this step if you don't need a restart
cube_012014  <- sits_cube(
    source = "BDC",
    collection = "SENTINEL-2-16D",
    data_dir = "./data",
    multicores = 6
)
plot(cube_012014, red = "B11", green = "B08", blue = "B02",
     date = "2025-07-28")
# build a vector data cube to include segments
# the raster images will not change
# the GPKG file will be included as the vector file
# see sits_cube.vector_cube for more information

cube_012014_vector <- sits_cube(
    source = "BDC",
    collection = "SENTINEL-2-16D",
    raster_cube = cube_012014,
    vector_dir = "./segments",
    vector_band = "segments"
)

# recover classification model
cnn_model <- readRDS("./models/tcnn_model.rds")

# recover exclusion mask
exclusion_mask = "./mask/prodes-amz-012014-exclusion-mask.gpkg"

cube_012014_vector_probs <- sits_classify(
    data = cube_012014_vector,
    ml_model = cnn_model,
#    exclusion_mask = exclusion_mask,
    memsize = 4,
    multicores = 2,
    gpu_memory = 12,
    output_dir = "./data/class",
    version = "tcnn-vector",
    verbose = TRUE,
    progress = TRUE
)
mask <- sf::st_read(exclusion_mask)
