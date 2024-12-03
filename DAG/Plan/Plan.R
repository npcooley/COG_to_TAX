###### -- collect precursor files to COG collection ---------------------------

suppressMessages(library(SynExtend))

TD_TARBALL <- tempfile(fileext = ".tar.gz")
download.file(url = "ftp://ftp.ncbi.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz",
              destfile = TD_TARBALL)
untar(tarfile = TD_TARBALL,
      files = "rankedlineage.dmp",
      exdir = tempdir())

file01 <- readLines(paste0(tempdir(),
                           "/rankedlineage.dmp"))
taxdump <- strsplit(x = file01,
                    split = "\t|\t",
                    fixed = TRUE)
taxdump <- do.call(rbind,
                   taxdump)
taxdump[, 10] <- gsub(x = taxdump[, 10],
                      pattern = "\t|",
                      fixed = TRUE,
                      replacement = "")
taxdump <- data.frame("TaxId" = taxdump[, 1],
                      "name" = taxdump[, 2],
                      "species" = taxdump[, 3],
                      "genera" = taxdump[, 4],
                      "family" = taxdump[, 5],
                      "order" = taxdump[, 6],
                      "class" = taxdump[, 7],
                      "phylum" = taxdump[, 8],
                      # "kingdom" = taxdump[, 9], # just get rid of this, it's annoying
                      "superkingdom" = taxdump[, 10])
rm(file01)
unlink(TD_TARBALL)

COG_LIST <- read.table(file = "ftp://ftp.ncbi.nlm.nih.gov/pub/COG/COG2024/data/cog-24.def.tab",
                       sep = "\t")
COG_KEY <- readLines("https://ftp.ncbi.nlm.nih.gov/pub/COG/COG2024/data/cog-24.fun.tab")

write.table(x = COG_LIST[, c(1,2)],
            quote = FALSE,
            append = FALSE,
            file = "COG_table.txt",
            row.names = TRUE,
            col.names = FALSE)

save(taxdump,
     COG_LIST,
     COG_KEY,
     file = "Inputdata.RData",
     compress = "xz")

