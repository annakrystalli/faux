#' Generate a sample with random intercepts for subjects and items
#'
#' \code{simdf_mixed} Produces a dataframe with the same distributions of by-subject and by-item random intercepts as an existing dataframe
#'
#' @param dat the existing dataframe
#' @param sub_n the number of subjects to simulate
#' @param item_n the number of items to simulate
#' @param dv the column name or index containing the DV
#' @param sub_id the column name or index for the subject IDs
#' @param item_id the column name or index for the item IDs
#' 
#' @return tibble
#' @examples
#' \donttest{simdf_mixed(faceratings, 10, 10, "rating", "rater_id", "face_id")}
#' @export

simdf_mixed <- function(dat, sub_n = 100, item_n = 25, 
                        dv = 1, sub_id = 2, item_id = 3) {
  # error checking -------------------------------------------------------------
  if (is.matrix(dat)) {
    dat = as.data.frame(dat)
  } else if (!is.data.frame(dat)) {
    stop("dat must be a data frame or matrix")
  }
  
  # get column names if specified by index
  if (is.numeric(dv)) dv <- names(dat)[dv]
  if (is.numeric(sub_id)) sub_id <- names(dat)[sub_id]
  if (is.numeric(item_id)) item_id <- names(dat)[item_id]
  
  lmer_formula <- paste0(dv, " ~ 1 + (1 | ", sub_id, ") + (1 | ", item_id, ")") %>%
    stats::as.formula()
  mod <- lme4::lmer(lmer_formula, data = dat)
  grand_i <- lme4::fixef(mod)
  
  sds <- lme4::VarCorr(mod) %>% as.data.frame()
  sub_i_sd <- dplyr::filter(sds, grp == sub_id) %>% dplyr::pull(sdcor)
  item_i_sd <- dplyr::filter(sds, grp == item_id) %>% dplyr::pull(sdcor)
  error_sd <- dplyr::filter(sds, grp == "Residual") %>% dplyr::pull(sdcor)
  
  # sample subject random intercepts -------------------------------------------
  new_sub <- tibble::tibble(
    sub_id = 1:sub_n,
    sub_i = stats::rnorm(sub_n, 0, sub_i_sd)
  )
  
  # sample item random intercepts ----------------------------------------------
  new_item <- tibble::tibble(
    item_id = 1:item_n,
    item_i = stats::rnorm(item_n, 0, item_i_sd)
  )
  
  new_obs <- expand.grid(
    sub_id = new_sub$sub_id,
    item_id = new_item$item_id
  ) %>%
    dplyr::left_join(new_sub, by = "sub_id") %>%
    dplyr::left_join(new_item, by = "item_id") %>%
    dplyr::mutate(dv = grand_i + sub_i + item_i + stats::rnorm(nrow(.), 0, error_sd))
  
  new_obs
}