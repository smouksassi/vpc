filter_dv <- function(x, verbose = FALSE, ...) {
  available_methods <- c("phx", "nonmem")
  if(sum(available_methods %in% class(x)) > 0)  {
    UseMethod("filter_dv", x)    
  } else {
    x    
  }
}


filter_dv.phx <- function(x, dv, verbose = FALSE, ...) {
  msg("Filtering rows with no DV values", verbose)
  x[!is.na(x[[dv]]),]
}


filter_dv.nonmem <- function(x, verbose = FALSE, ...) {
  if ("EVID" %in% names(x)){
    msg("Filtering rows where EVID not 0", verbose)
    x <- x[x[["EVID"]] == 0,]
  } 
  if("MDV" %in% names(x)) {
    msg("Filtering rows where MDV not 0", verbose) 
    x <- x[x[["MDV"]] == 0,]
  } 
  if(sum(c("EVID", "MDV") %in% names(x)) == 0) {
    msg("No MDV or EVID columns found to filter on", verbose)
  }
  return(x)
}