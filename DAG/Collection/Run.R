###### -- collect the indicated COG and do some stuff -------------------------

suppressMessages(library(DECIPHER))

load(file = "Inputdata.RData",
     verbose = TRUE)

ARGS <- commandArgs(trailingOnly = TRUE)
TARGET <- ARGS[1]
ID <- ARGS[2]

tmp01 <- tempfile()

query1 <- paste0("esearch -db protein",
                 " -query '",
                 TARGET,
                 "'",
                 " | efetch -format fasta > ",
                 tmp01)

system(command = query1,
       timeout = 6000)

seqs <- readAAStringSet(filepath = tmp01)
unlink(tmp01)

accessions <- sapply(X = strsplit(x = names(seqs),
                                  split = " ",
                                  fixed = TRUE),
                     FUN = function(x) {
                       x[1]
                     },
                     simplify = TRUE)
w1 <- grepl(pattern = "|",
            x = accessions,
            fixed = TRUE)
if (sum(w1) > 0) {
  accessions[w1] <- sapply(X = strsplit(x = accessions[w1],
                                        split = "|",
                                        fixed = TRUE),
                           FUN = function(x) {
                             x[2]
                           })
}

tmp01 <- tempfile()
writeLines(text = accessions,
           con = tmp01,
           sep = ", ")
query2 <- paste0("cat ",
                 tmp01,
                 " | ",
                 "epost -db protein",
                 " | ",
                 "esummary",
                 " | ",
                 "xtract -pattern DocumentSummary -element Caption TaxId")
taxids <- system(command = query2,
                 intern = TRUE,
                 timeout = 6000)
unlink(tmp01)

taxmap <- do.call(rbind,
                  strsplit(x = taxids,
                           split = "\t",
                           fixed = TRUE))

# step 2 remove weirdos and cluster
names(seqs) <- accessions
seqs02 <- RemoveGaps(seqs[width(seqs) >= quantile(x = width(seqs), c(0.05, 0.95))[1] &
                            width(seqs) <= quantile(x = width(seqs), c(0.05, 0.95))[2]])

# seqs02 <- RemoveGaps(unique(seqs02))

cl01 <- Clusterize(myXStringSet = seqs02,
                   cutoff = seq(from = 0.5,
                                to = 0,
                                by = -0.1),
                   processors = NULL,
                   invertCenters = TRUE)

# step 3 collect centers and the peripheral sequences separately
u1 <- unique(cl01$cluster_0_2[cl01$cluster_0_2 < 0])
avl_ids <- taxmap[match(x = gsub(x = rownames(cl01),
                                 replacement = "",
                                 pattern = "\\..+"),
                        table = taxmap[, 1]), 2]

pBar <- txtProgressBar(style = 1)
PBAR <- length(u1)
center_tax <- non_center_tax <- center_seq <- vector(mode = "list",
                                                     length = PBAR)
tstart <- Sys.time()
for (m1 in seq_along(u1)) {
  u2 <- which(cl01$cluster_0_2 == u1[m1])
  if (length(u2) > 0) {
    center_tax[[m1]] <- taxdump[taxdump$TaxId %in% avl_ids[u2], -1L]
    center_seq[[m1]] <- seqs02[u2[1]] # there can be multiple centers, just grab the first sequence
    # may want to do something smarter with labels for the center later, but for now we ball
  }
  u2 <- which(cl01$cluster_0_2 == abs(u1[m1]))
  if (length(u2) > 0) {
    non_center_tax[[m1]] <- taxdump[taxdump$TaxId %in% avl_ids[u2], -1L]
  }
  
  setTxtProgressBar(pb = pBar,
                    value = m1 / PBAR)
}
close(pBar)
tend <- Sys.time()
print(tend - tstart)

pBar <- txtProgressBar(style = 1L)
taxlabel <- vector(mode = "character",
                   length = PBAR)
tstart <- Sys.time()
for (m1 in seq_along(taxlabel)) {
  ph1 <- do.call(rbind,
                 c(center_tax[m1],
                   non_center_tax[m1]))
  ph2 <- apply(X = ph1,
               MARGIN = 2,
               FUN = function(x) {
                 unique(x[nchar(x) > 0])
               })
  ph2 <- ph2[length(ph2):1]
  
  # drop any empty levels
  if (any(lengths(ph2) == 0L)) {
    ph2 <- ph2[lengths(ph2) > 0]
  }
  # drop any levels occupied by only 
  
  if (length(ph2[1]) == 1L) {
    ph3 <- paste(unname(unlist(ph2[lengths(ph2) == 1])),
                 collapse = "; ")
    ph3 <- paste("Root",
                 TARGET,
                 ph3,
                 sep = "; ")
    if (any(lengths(ph2) > 1L)) {
      ph3 <- paste(ph3,
                   paste0("MULTI_",
                          toupper(names(ph2[which(lengths(ph2) > 1)[1]]))),
                   sep = "; ")
    } else {
      # do nothing?
    }
  } else {
    # multiple kingdoms in the cluster, probably unresolvable ?
    next
  }
  taxlabel[m1] <- ph3
  setTxtProgressBar(pb = pBar,
                    value = m1 / PBAR)
}
close(pBar)
tend <- Sys.time()
print(tend - tstart)

seqs03 <- RemoveGaps(do.call(c,
                             center_seq))

res <- list("target" = TARGET,
            "clustered_ids" = rownames(cl01),
            "non_unique_seqs" = seqs02,
            "center_seqs" = seqs03,
            "labels" = taxlabel,
            "source_tax" = taxmap)

save(res,
     file = paste0("Result",
                   formatC(x = as.integer(ID),
                           flag = "0",
                           format = "d",
                           width = 5),
                   ".RData"),
     compress = "xz")




