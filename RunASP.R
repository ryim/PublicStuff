library(ArraySizePredictor)

args = commandArgs(trailingOnly=TRUE)
# print(args[1])

# Get the settings in
ASPSettings <- loadDefaultASPSettings()
ASPSettings$outputNormData <- TRUE
ASPSettings$outputASKData <- TRUE
ASPSettings$outputPloidyEst <- TRUE
ASPSettings$sampleName <- args[1]
ASPSettings$outDir <- paste0(ASPSettings$sampleName, "_outData")
fileName <- args[2]

# Run ASP
resultsByArray <- runASP(fileName, ASPSettings)

# Output ASP Results
write.table(resultsByArray,
            file = paste0(ASPSettings$outDir, 
                          '/', 
                          ASPSettings$sampleName, 
                          '_ASPResults.tsv'),
            quote = FALSE,
            row.names = FALSE,
            sep = '\t')
