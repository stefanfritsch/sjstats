#' @title Tjur's Coefficient of Discrimination
#' @name cod
#'
#' @description This method calculates the Coefficient of Discrimination \code{D}
#'                for generalized linear (mixed) models for binary data. It is
#'                an alternative to other Pseudo-R-squared values
#'                like Nakelkerke's R2 or Cox-Snell R2.
#'
#' @param x Fitted \code{\link{glm}} or \code{\link[lme4]{glmer}} model.
#'
#' @return The \code{D} Coefficient of Discrimination, also known as
#'           Tjur's R-squared value.
#'
#' @note The Coefficient of Discrimination \code{D} can be read like any
#'         other (Pseudo-)R-squared value.
#'
#' @references Tjur T (2009) Coefficients of determination in logistic regression models -
#'               a new proposal: The coefficient of discrimination. The American Statistician,
#'               63(4): 366-372
#'
#' @seealso \code{\link{r2}} for Nagelkerke's and Cox and Snell's pseudo
#'            r-squared coefficients.
#'
#' @examples
#' library(sjmisc)
#' data(efc)
#'
#' # Tjur's R-squared value
#' efc$services <- ifelse(efc$tot_sc_e > 0, 1, 0)
#' fit <- glm(services ~ neg_c_7 + c161sex + e42dep,
#'            data = efc, family = binomial(link = "logit"))
#' cod(fit)
#'
#' @importFrom stats predict predict.glm residuals
#' @export
cod <- function(x) {
  # check for valid object class
  if (!inherits(x, c("glmerMod", "glm"))) {
    stop("`x` must be an object of class `glm` or `glmerMod`.", call. = F)
  }

  # mixed models (lme4)
  if (inherits(x, "glmerMod")) {
    # check for package availability
    y <- lme4::getME(x, "y")
    pred <- stats::predict(x, type = "response", re.form = NULL)
  } else {
    y <- x$y
    pred <- stats::predict.glm(x, type = "response")
  }

  # delete pred for cases with missing residuals
  if (anyNA(stats::residuals(x))) pred <- pred[!is.na(stats::residuals(x))]

  categories <- unique(y)
  m1 <- mean(pred[which(y == categories[1])], na.rm = T)
  m2 <- mean(pred[which(y == categories[2])], na.rm = T)

  cod = abs(m2 - m1)
  names(cod) <- "D"

  structure(class = "sjstats_r2", list(cod = cod))
}



#' @title Compute r-squared of (generalized) linear (mixed) models
#' @name r2
#'
#' @description Compute R-squared values of linear (mixed) models, or
#'                pseudo-R-squared values for generalized linear (mixed) models.
#'
#' @param x Fitted model of class \code{lm}, \code{glm}, \code{lmerMod}/\code{lme}
#'            or \code{glmerMod}.
#' @param n Optional, a \code{lmerMod} object, representing the fitted null-model
#'          (unconditional model) to \code{x}. If \code{n} is given, the pseudo-r-squared
#'          for random intercept and random slope variances are computed
#'          (\cite{Kwok et al. 2008}) as well as the Omega squared value
#'          (\cite{Xu 2003}). See 'Examples' and 'Details'.
#'
#' @return \itemize{
#'           \item For linear models, the r-squared and adjusted r-squared values.
#'           \item For linear mixed models, the r-squared and Omega-squared values.
#'           \item For \code{glm} objects, Cox & Snell's and Nagelkerke's pseudo r-squared values.
#'           \item For \code{glmerMod} objects, Tjur's coefficient of determination.
#'         }
#'
#' @note If \code{n} is given, the Pseudo-R2 statistic is the proportion of
#'          explained variance in the random effect after adding co-variates or
#'          predictors to the model, or in short: the proportion of the explained
#'          variance in the random effect of the full (conditional) model \code{x}
#'          compared to the null (unconditional) model \code{n}.
#'          \cr \cr
#'          The Omega-squared statistics, if \code{n} is given, is 1 - the proportion
#'          of the residual variance of the full model compared to the null model's
#'          residual variance, or in short: the the proportion of the residual
#'          variation explained by the covariates.
#'          \cr \cr
#'          The r-squared statistics for linear mixed models, if the unconditional
#'          model is also specified (see \code{n}), is the difference of the total
#'          variance of the null and full model divided by the total variance of
#'          the null model.
#'          \cr \cr
#'          Alternative ways to assess the "goodness-of-fit" is to compare the ICC
#'          of the null model with the ICC of the full model (see \code{\link{icc}}).
#'
#' @details For linear models, the r-squared and adjusted r-squared value is returned,
#'          as provided by the \code{summary}-function.
#'          \cr \cr
#'          For linear mixed models, an r-squared approximation by computing the
#'          correlation between the fitted and observed values, as suggested by
#'          \cite{Byrnes (2008)}, is returned as well as a simplified version of
#'          the Omega-squared value (1 - (residual variance / response variance),
#'          \cite{Xu (2003)}, \cite{Nakagawa, Schielzeth 2013}), unless \code{n}
#'          is specified.
#'          \cr \cr
#'          If \code{n} is given, for linear mixed models pseudo r-squared measures based
#'          on the variances of random intercept (tau 00, between-group-variance)
#'          and random slope (tau 11, random-slope-variance), as well as the
#'          r-squared statistics as proposed by \cite{Snijders and Bosker 2012} and
#'          the Omega-squared value (1 - (residual variance full model / residual
#'          variance null model)) as suggested by \cite{Xu (2003)} are returned.
#'          \cr \cr
#'          For generalized linear models, Cox & Snell's and Nagelkerke's
#'          pseudo r-squared values are returned.
#'          \cr \cr
#'          For generalized linear mixed models, the coefficient of determination
#'          as suggested by \cite{Tjur (2009)} (see also \code{\link{cod}}). Note
#'          that \emph{Tjur's D} is restricted to models with binary response.
#'          \cr \cr
#'          More ways to compute coefficients of determination are shown
#'          in this great \href{http://bbolker.github.io/mixedmodels-misc/glmmFAQ.html#model-summaries-goodness-of-fit-decomposition-of-variance-etc.}{GLMM faq}.
#'          Furthermore, see \code{\link[MuMIn]{r.squaredGLMM}} or
#'          \code{\link[piecewiseSEM]{rsquared}} for conditional and marginal
#'          r-squared values for GLMM's.
#'
#' @seealso \code{\link{rmse}} for more methods to assess model quality.
#'
#' @references \itemize{
#'               \item \href{http://glmm.wikidot.com/faq}{DRAFT r-sig-mixed-models FAQ}
#'               \item Bolker B et al. (2017): \href{http://bbolker.github.io/mixedmodels-misc/glmmFAQ.html}{GLMM FAQ.}
#'               \item Byrnes, J. 2008. Re: Coefficient of determination (R^2) when using lme() (\url{https://stat.ethz.ch/pipermail/r-sig-mixed-models/2008q2/000713.html})
#'               \item Kwok OM, Underhill AT, Berry JW, Luo W, Elliott TR, Yoon M. 2008. Analyzing Longitudinal Data with Multilevel Models: An Example with Individuals Living with Lower Extremity Intra-Articular Fractures. Rehabilitation Psychology 53(3): 370–86. \doi{10.1037/a0012765}
#'               \item Nakagawa S, Schielzeth H. 2013. A general and simple method for obtaining R2 from generalized linear mixed-effects models. Methods in Ecology and Evolution, 4(2):133–142. \doi{10.1111/j.2041-210x.2012.00261.x}
#'               \item Rabe-Hesketh S, Skrondal A. 2012. Multilevel and longitudinal modeling using Stata. 3rd ed. College Station, Tex: Stata Press Publication
#'               \item Raudenbush SW, Bryk AS. 2002. Hierarchical linear models: applications and data analysis methods. 2nd ed. Thousand Oaks: Sage Publications
#'               \item Snijders TAB, Bosker RJ. 2012. Multilevel analysis: an introduction to basic and advanced multilevel modeling. 2nd ed. Los Angeles: Sage
#'               \item Xu, R. 2003. Measuring explained variation in linear mixed effects models. Statist. Med. 22:3527-3541. \doi{10.1002/sim.1572}
#'               \item Tjur T. 2009. Coefficients of determination in logistic regression models - a new proposal: The coefficient of discrimination. The American Statistician, 63(4): 366-372
#'             }
#'
#' @examples
#' library(sjmisc)
#' library(lme4)
#' fit <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#' r2(fit)
#'
#' data(efc)
#' fit <- lm(barthtot ~ c160age + c12hour, data = efc)
#' r2(fit)
#'
#' # Pseudo-R-squared values
#' efc$services <- ifelse(efc$tot_sc_e > 0, 1, 0)
#' fit <- glm(services ~ neg_c_7 + c161sex + e42dep,
#'            data = efc, family = binomial(link = "logit"))
#' r2(fit)
#'
#' # Pseudo-R-squared values for random effect variances
#' fit <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#' fit.null <- lmer(Reaction ~ 1 + (Days | Subject), sleepstudy)
#' r2(fit, fit.null)
#'
#'
#' @importFrom stats model.response model.frame fitted var residuals
#' @importFrom sjmisc is_empty
#' @export
r2 <- function(x, n = NULL) {
  rsq <- NULL
  osq <- NULL
  adjr2 <- NULL

  # do we have a glm? if so, report pseudo_r2
  if (inherits(x, "glm")) {
    return(pseudo_ralt(x))
    # do we have a glmer?
  } else if (inherits(x, "glmerMod")) {
    return(cod(x))
    # do we have a simple linear model?
  } else if (inherits(x, "lm")) {
    rsq <- summary(x)$r.squared
    adjr2 <- summary(x)$adj.r.squared

    # name vectors
    names(rsq) <- "R2"
    names(adjr2) <- "adj.R2"

    # return results
    return(structure(class = "sjstats_r2", list(r2 = rsq, adjr2 = adjr2)))
    # else do we have a mixed model?
  } else if (inherits(x, "plm")) {
    rsq <- summary(x)$r.squared[1]
    adjr2 <- summary(x)$r.squared[2]

    # name vectors
    names(rsq) <- "R2"
    names(adjr2) <- "adj.R2"

    # return results
    return(structure(class = "sjstats_r2", list(r2 = rsq, adjr2 = adjr2)))
  } else if (inherits(x, c("lmerMod", "lme"))) {
    # do we have null model?
    if (!is.null(n)) {
      # compute tau for both models
      tau_full <- icc(x)
      tau_null <- icc(n)

      # get taus. tau.00 is the random intercept variance, i.e. for growth models,
      # the difference in the outcome's mean at first time point
      rsq0 <- (attr(tau_null, "tau.00") - attr(tau_full, "tau.00")) / attr(tau_null, "tau.00")

      # tau.11 is the variance of the random slopes, i.e. how model predictors
      # affect the trajectory of subjects over time (for growth models)
      rsq1 <- (attr(tau_null, "tau.11") - attr(tau_full, "tau.11")) / attr(tau_null, "tau.11")

      # get r2
      rsq <- ((attr(tau_null, "tau.00") + attr(tau_null, "sigma_2")) -
        (attr(tau_full, "tau.00") + attr(tau_full, "sigma_2"))) /
        (attr(tau_null, "tau.00") + attr(tau_null, "sigma_2"))

      # get omega-squared
      osq <- 1 - ((attr(tau_full, "sigma_2") / attr(tau_null, "sigma_2")))

      # if model has no random slope, we need to set this value to NA
      if (is.null(rsq1) || sjmisc::is_empty(rsq1)) rsq1 <- NA

      # name vectors
      names(rsq0) <- "R2(tau-00)"
      names(rsq1) <- "R2(tau-11)"
      names(rsq) <- "R2"
      names(osq) <- "O2"

      # return results
      return(structure(class = "sjstats_r2", list(r2_tau00 = rsq0, r2_tau11 = rsq1, r2 = rsq, o2 = osq)))
    } else {
      # compute "correlation"
      lmfit <-  lm(resp_val(x) ~ stats::fitted(x))
      # get r-squared
      rsq <- summary(lmfit)$r.squared
      # get omega squared
      osq <- 1 - stats::var(stats::residuals(x)) / stats::var(resp_val(x))
      # name vectors
      names(rsq) <- "R2"
      names(osq) <- "O2"
      # return results
      return(structure(class = "sjstats_r2", list(r2 = rsq, o2 = osq)))
    }
  } else {
    warning("`r2` only works on linear (mixed) models of class \"lm\", \"lme\" or \"lmerMod\".", call. = F)
    return(NULL)
  }
}


#' @importFrom stats logLik update nobs
pseudo_ralt <- function(x) {
  ll <- stats::logLik(x)
  ll0 <- stats::logLik(stats::update(x, ~1))
  n <- stats::nobs(x)

  CoxSnell <- 1 - exp(2 * (ll0 - ll) / n)
  Nagelkerke <- CoxSnell / (1 - exp(ll0 * 2 / n))

  names(CoxSnell) <- "CoxSnell"
  names(Nagelkerke) <- "Nagelkerke"

  structure(class = "sjstats_r2", list(CoxSnell = CoxSnell, Nagelkerke = Nagelkerke))
}
