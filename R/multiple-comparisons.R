#' GetApcDF
#' 
#' makes average predictive comparison for all specified inputs
#' 
#' @param model Either a function (from a data frame to vector of predictions) or a model we know how to deal with (lm, glm)
#' @param df data frame with data
#' @param inputVars inputs to the model
#' @param ... extra parguments passed to GetPairs used to control Weight function
#' @export
#' @examples
#' n <- 200
#' x1 <- runif(n = n, min = 0, max = 1)
#' x2 <- runif(n = n, min = 0, max = 1)
#' x3 <- runif(n = n, min = 0, max = 10)
#' y <- 2 * x1 + (-2) * x2 + 1 * x3 + rnorm(n, sd = 0.1)
#' df <- data.frame(x1, x2, x3, y)
#' fittedLm <- lm(y ~ ., data = df)
#' apcDF <- GetPredCompsDF(fittedLm, df = df)
#' apcDF
GetPredCompsDF <- function(model, df, inputVars = NULL, ...) {
  
  # If inputVars is null, we can try to get the list of inputs from the model:
  if (is.null(inputVars)) {
    inputVars <- GetInputVarsFromModel(model)
  }
  apcList <-  Map(function(currentVar) {
    cat(paste("Working on:", currentVar, "\n"))
    data.frame(Input = currentVar,
               GetSingleInputApcs(model, 
                                       df, 
                                       currentVar, 
                                       c(setdiff(inputVars, currentVar)),
                                       ...))},
    inputVars
  )
  apcDF <- do.call(rbind, apcList)
  return(apcDF)
}

#' PlotApcDF
#' 
#' plots the output of GetApcDF -- this is my preferred display for now
#' 
#' @param apcDF the output of GetApcDF
#' @export
#' @examples
#' n <- 200
#' x1 <- runif(n = n, min = 0, max = 1)
#' x2 <- runif(n = n, min = 0, max = 1)
#' x3 <- runif(n = n, min = 0, max = 10)
#' y <- 2 * x1 + (-2) * x2 + 1 * x3 + rnorm(n, sd = 0.1)
#' df <- data.frame(x1, x2, x3, y)
#' fittedLm <- lm(y ~ ., data = df)
#' apcDF <- GetPredCompsDF(fittedLm, df = df)
#' PlotPredCompsDF(apcDF, variant = "PerUnitInput") + theme_gray(base_size = 18)
PlotPredCompsDF <- function(apcDF, variant="Impact") {
  xLabel <- switch(variant, 
                   "Impact"="Avg Change in Output",
                   "PerUnitInput"="Avg Change in Output Per Unit Input",
                   stop("Unknown Predcomps Variant"))
  
  apcDF <- apcDF[c("Input", grep(paste0("^",variant,"\\."), names(apcDF), value=TRUE))]
  names(apcDF) <- gsub(paste0("^",variant,"\\."), "", names(apcDF))
  
  maxAPC <- max(abs(apcDF$Absolute))  
  apcDF$Input <- reorder(apcDF$Input, apcDF$Absolute)
  longAPCs <- melt(apcDF, id="Input", value.name = "Value", variable.name = "Type")
  longAPCs2 <- rbind(
    longAPCs,
    transform(subset(longAPCs, Type=="Absolute"), Value=-Value)
  )
  longAPCs2 <- longAPCs2[order(factor(longAPCs2$Type, levels=c("Absolute", "Signed"))), ]  
  
  return(
    ggplot(longAPCs2) +
      geom_point(aes(y = Input, x=Value, color=Type, shape=Type, size=Type)) +
      scale_x_continuous(limits=c(-maxAPC, maxAPC)) +
      scale_size_discrete(range=c(3,4)) +
      ggtitle(variant) +
      geom_vline(aes(xintercept=0), alpha=.5) +
      xlab(xLabel)
  )
}
