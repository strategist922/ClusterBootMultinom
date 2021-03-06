% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calc_ppci.R
\name{calc.ppci}
\alias{calc.ppci}
\title{Calculate Predicted Probabilities and 95\% Confidence Intervals for Each Outcome Level vs.
Continuous Covariate}
\usage{
calc.ppci(design.matrix, model.obj, use.coefs, use.vcov)
}
\arguments{
\item{design.matrix}{Design matrix with covariate values, stacked by outcome level.}

\item{model.obj}{\code{vglm()} model object, used to get number of outcome levels and
label linear predictors.}

\item{use.coefs}{Numeric vector of coefficients, if not taken from original model (eg,
\code{colMeans}(matrix of bootstrapped coefficients).}

\item{use.vcov}{Numeric matrix to use as variance-covariance matrix (eg,
var(matrix of bootstrapped coefficients)).}
}
\value{
List of linear predictors (LinearPredictors); variance-covariance matrix of
  linear predictors (VarianceLP), predicted probabilities (PredictedProbs) and
  their variance-covariance matrix (VariancePPs); SEs (ProbsSes), lower and upper
  confidence limits of predicted probabilities (ProbsSEs, ProbsLCLs and ProbsUCLs,
  respectively). Each has (number of outcome levels - 1) columns, representing the
  quantities for all outcome levels except the reference.
}
\description{
Given a matrix of bootstrapped coefficient estimates from multinomial regression using
\code{vglm()}, calculates linear predictors, predicted probabilities, and SEs and
confidence limits for a continuous exposure variable at all non-reference levels of the
outcome. Has the capabilitiy to include restricted cubic splines using \code{rcs()}.
}
\examples{
## Create data frame
df <- data.frame(id = sample(1:20, size = 100, replace = TRUE),
                 x1 = rnorm(n = 100),
                 x2 = rbinom(p = 0.75, n = 100, size = 1),
                 y = sample(LETTERS[1:3], size = 100, replace = TRUE))
df <- df[order(df$id),]
df$time <- unlist(lapply(1:length(unique(df$id)),
                         FUN = function(idnum){ 1:nrow(df[df$id == unique(df$id)[idnum],]) }))

## Using create.sampdata(), generate list of cluster bootstrapped data sets
bootdata.list <- create.sampdata(org.data = df,
                                 id.var = 'id',
                                 n.sets = 25)

## Fit model to original and bootstrapped data frame, saving errors and warnings to .txt file
boot.fits.a <- multi.bootstrap(org.data = df,
                               data.sets = bootdata.list,
                               ref.outcome = grep('A', levels(df$y)),
                               multi.form = as.formula('y ~ x1 + x2'))

## Create matrices of coefficients for all bootstrap fits
boot.matrix.a <- do.call(rbind,
                         lapply(boot.fits.a$boot.models,
                                FUN = function(x){ x@coefficients }))

## Calculate predicted probs and CIs for x1 at outcomes B, C
## Design matrix: first two columns = intercepts, second two set X2 = 1
design.tmp <- matrix(c(1, 0, 0, 1, 1, 0, 0, 1), nrow = 2)
x1.vals <- sort(unique(df$x1))

## Add all unique x1 values to get complete design matrix
x1.design <- do.call(rbind,
                     lapply(1:nrow(design.tmp), FUN = function(r){
                       tmp <- matrix(rep(c(design.tmp[r,],
                                           rep(0, (length(unique(df$y)) - 1))),
                                         length(x1.vals)),
                                     nrow = length(x1.vals), byrow = TRUE)
                       tmp[,(ncol(design.tmp) + r)] <- x1.vals
                       tmp
                     }))

## Calculate linear predictors, predicted probabilities, etc
x1probs <- calc.ppci(design.matrix = x1.design,
                     model.obj = boot.fits.a$org.model,
                     use.coefs = colMeans(boot.matrix.a),
                     use.vcov = var(boot.matrix.a))
}
\seealso{
\code{\link[VGAM]{vglm}}, which this function assumes you are using;
\code{multi.plot.probs}, which calls this function; \code{rcs()}.
}

