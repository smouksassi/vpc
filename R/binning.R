#' Calculate appropriate bin separators for vpc
#' 
#' @param dat data frame
#' @param type auto-binning type: "density", "time", or "data"
#' @param n_bins number of bins to use. For "density" the function might not return a solution with the exact number of bins.
#' @param verbose show warnings and other messages (TRUE or FALSE)
#' @return A vector of bin separators
#' @export auto_bin
#' @seealso \code{\link{vpc}}
#' @details
#' This function calculates bin separators (e.g. for use in a vpc) based on nadirs in the density functions for the indenpendent variable

auto_bin <- function (dat, type="kmeans", n_bins = 8, verbose = FALSE) {
  all_bins <- list()
  l_bins <- c()
  if (is.null(type) || type == "none") {
    msg("No binning performed.", verbose)
    return(unique(dat[["idv"]]))    
  }
  # use R's native binning approaches?
  if(!is.null(type) && type %in% c("jenks", "kmeans", "pretty", "quantile", "hclust", "sd", "bclust", "fisher")) {
    suppressWarnings({
      if(class(n_bins) != "numeric" | is.null(n_bins)) {
        bins <- classIntervals(dat[["idv"]], style = type)                
      } else {
        bins <- classIntervals(dat[["idv"]], n = n_bins-1, style = type)        
      }      
    })
    return(bins$brks)      
  }
  if (n_bins == "auto") {
    msg("Automatic optimization of bin number is not available for this binning method, reverting to 8 bins.", verbose)
    n_bins <- 8
  }
  n_bins <- n_bins + 1 # bin_separators
  if(type != "time" & type != "data") {
    if (type == "density" || type == "auto") {
      bws <- diff(range(dat[["idv"]])) * seq(from=0.01, to = .25, by=0.01)
      for (i in seq(bws)) {
        d <- density(dat[["idv"]], bw=bws[i])
        all_bins[[i]] <- c(0, d$x[find_nadirs(d$y)], max(dat[["idv"]])*1.01)
        l_bins[i] <- length(all_bins[[i]])
      }     
      return(all_bins[[order(abs(l_bins - n_bins))[1]]]) # return closest to requested bins
    }
    stop("Specified binning method not recognized!")
  } else {
    if (type == "time") {
      tmp <- levels(cut(x = unique(dat[["idv"]]), breaks = n_bins, right = TRUE))
      tmp <- gsub("\\(", "", tmp)
      tmp <- gsub("\\]", "", tmp)
      tmp2 <- unlist(strsplit(tmp, ","))
      sel <- 1:(length(tmp2)/2)*2 - 1
      bins <- c(as.num(tmp2[sel]), max(dat[["idv"]])*1.001)
      return(bins)
    }
    if (type == "data") {
      sorted <- sort(dat[["idv"]])
      tmp <- levels(cut(x = 1:length(sorted), breaks = n_bins, right = TRUE))
      tmp <- gsub("\\(", "", tmp)
      tmp <- gsub("\\]", "", tmp)
      tmp2 <- unlist(strsplit(tmp, ","))
      sel <- 1:(length(tmp2)/2)*2 - 1
      idx <- as.num(tmp2[sel])
      idx[idx < 0] <- 0
      bins <- c(sorted[idx], max(dat[["idv"]])*1.001)
      return(bins)    
    }    
  }
  return(paste0("Binning method ", type, " not implemented yet!"))
}

find_nadirs <- function (x, thresh = 0) {
  pks <- which(diff(sign(diff(x, na.pad = FALSE)), na.pad = FALSE) > 0) + 2
  if (!missing(thresh)) {
    pks[x[pks - 1] - x[pks] > thresh]
  }
  else pks
}

#' Function to bin data based on a vector of bin separators, e.g. for use in VPC
#' 
#' @param x data
#' @param bins numeric vector specifying bin separators
#' @param idv variable in the data specifies the independent variable (e.g. "time")
#' @export
bin_data <- function(x, bins = c(0, 3, 5, 7), idv = "time") {
  x$bin <- cut(x[[idv]], bins, labels = FALSE, right=FALSE)
  return(x)
}
