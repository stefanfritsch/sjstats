#' @title Coefficient of Variation
#' @name cv
#' @description Compute coefficient of variation for single variables
#'                (standard deviation divided by mean) or for fitted
#'                linear (mixed effects) models (root mean squared error
#'                (RMSE) divided by mean of dependent variable).
#'
#' @param x (Numeric) vector or a fitted linear model of class
#'          \code{\link{lm}}, \code{\link[lme4]{merMod}} (\pkg{lme4}) or
#'          \code{\link[nlme]{lme}} (\pkg{nlme}).
#' @param ... More fitted model objects, to compute multiple coefficients of
#'              variation at once.
#' @return The coefficient of variation of \code{x}.
#'
#' @details The advantage of the cv is that it is unitless. This allows
#'            coefficient of variation to be compared to each other in ways
#'            that other measures, like standard deviations or root mean
#'            squared residuals, cannot be.
#'            \cr \cr
#'            \dQuote{It is interesting to note the differences between a model's CV
#'            and R-squared values. Both are unitless measures that are indicative
#'            of model fit, but they define model fit in two different ways: CV
#'            evaluates the relative closeness of the predictions to the actual
#'            values while R-squared evaluates how much of the variability in the
#'            actual values is explained by the model.}
#'            \cite{(\href{http://www.ats.ucla.edu/stat/mult_pkg/faq/general/coefficient_of_variation.htm}{source: UCLA-FAQ})}
#'
#' @seealso \code{\link{rmse}}
#'
#' @references Everitt, Brian (1998). The Cambridge Dictionary of Statistics. Cambridge, UK New York: Cambridge University Press
#'
#' @examples
#' data(efc)
#' cv(efc$e17age)
#'
#' fit <- lm(neg_c_7 ~ e42dep, data = efc)
#' cv(fit)
#'
#' library(lme4)
#' fit <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#' cv(fit)
#'
#' library(nlme)
#' fit <- lme(Reaction ~ Days, random = ~ Days | Subject, data = sleepstudy)
#' cv(fit)
#'
#' @importFrom stats sd
#' @export
cv <- function(x, ...) {
  # return value
  cv_ <- cv_helper(x)

  # check if we have multiple parameters
  if (nargs() > 1) {
    # get input list
    params_ <- list(...)
    cv_ <- c(cv_, sapply(params_, cv_helper))
  }

  cv_
}


cv_helper <- function(x) {
  # check if we have a fitted linear model
  if (inherits(x, c("lm", "lmerMod", "lme", "merModLmerTest")) && !inherits(x, "glm")) {
    # get response
    dv <- resp_val(x)
    mw <- mean(dv, na.rm = TRUE)
    stddev <- rmse(x)
  } else {
    mw <- mean(x, na.rm = TRUE)
    stddev <- stats::sd(x, na.rm = TRUE)
  }

  # check if mean is zero?
  if (mw == 0)
    stop("Mean of dependent variable is zero. Cannot compute model's coefficient of variation.", call. = F)

  stddev / mw
}
