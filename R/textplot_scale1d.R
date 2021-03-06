#' plot a fitted scaling model
#' 
#' Plot the results of a fitted scaling model, from (e.g.) a predicted 
#' \link{textmodel_wordscores} model or a fitted \link{textmodel_wordfish}
#' model. Either document or feature parameters may be plotted: an ideal
#' point-style plot (estimated document position plus confidence interval on the
#' x-axis, document labels on the y-axis) with optional renaming and sorting, or
#' as a plot of estimated feature-level parameters (estimated feature positions
#' on the x-axis, and a measure of relative frequency or influence on the
#' y-axis, with feature names replacing plotting points with some being chosen
#' by the user to be highlighted).
#' @param x the fitted or predicted scaling model object to be plotted
#' @param margin \code{"documents"} to plot estimated document scores (the
#'   default) or \code{"features"} to plot estimated feature scores by a measure
#'   of relative frequency
#' @param sort if \code{TRUE} (the default), order points from low to high 
#'   score. If a vector, order according to these values from low to high. Only 
#'   applies when \code{margin = "documents"}.
#' @param groups optional grouping variable for sorting categories of the documents.  
#' Only applies when \code{margin = "documents"}.
#' @param doclabels a vector of names for document; if left NULL (the default), 
#'   docnames will be used
#' @param highlighted a vector of feature names to draw attention to in a 
#'   feature plot; only applies if \code{margin = "features"}
#' @param highlighted_color color for highlighted terms in \code{highlighted}
#' @param alpha A number between 0 and 1 (default 0.5) representing the level of
#'   alpha transparency used to overplot feature names in a feature plot; only 
#'   applies if \code{margin = "features"}
#' @return a \pkg{ggplot2} object
#' @export
#' @references Jonathan Slapin and Sven-Oliver Proksch.  2008. "A Scaling Model 
#'   for Estimating Time-Series Party Positions from Texts." \emph{American 
#'   Journal of Political Science} 52(3):705-772.
#' @author Kenneth Benoit, Stefan Mueller, and Adam Obeng
#' @keywords textplot
#' @examples
#' ## wordfish
#' wfm <- textmodel_wordfish(dfm(data_corpus_irishbudget2010), dir = c(6,5))
#' 
#' # plot estimated document positions
#' doclab <- apply(docvars(data_corpus_irishbudget2010, c("name", "party")), 
#'                 1, paste, collapse = " ")
#' textplot_scale1d(wfm, doclabels = doclab)
#' textplot_scale1d(wfm, doclabels = doclab,
#'                  groups = docvars(data_corpus_irishbudget2010, "party"))
#' 
#' # plot estimated word positions
#' textplot_scale1d(wfm, margin = "features", 
#'                  highlighted = c("government", "global", "children", 
#'                                  "bank", "economy", "the", "citizenship",
#'                                  "productivity", "deficit"))
textplot_scale1d <- function(x, margin = c("documents", "features"), doclabels = NULL, 
                              sort = TRUE, groups = NULL, highlighted = NULL, alpha = 0.7, 
                              highlighted_color = "black") {
    UseMethod("textplot_scale1d")
}

#' @noRd
#' @importFrom stats reorder aggregate
#' @importFrom ggplot2 ggplot aes geom_point element_blank geom_pointrange 
#' @importFrom ggplot2 coord_flip xlab ylab theme_bw geom_text theme geom_point
#' @importFrom ggplot2 facet_grid element_line
#' @export
textplot_scale1d.textmodel_wordfish_fitted <- 
    function(x, margin = c("documents", "features"), doclabels = NULL, 
             sort = TRUE, groups = NULL, highlighted = NULL, alpha = 0.7, 
             highlighted_color = "black") {
        
    margin <- match.arg(margin)
    
    if (margin == "documents") {
        n <- length(x@theta)
        if (is.null(doclabels)) 
            doclabels <- x@docs
        stopifnot(length(doclabels) == n)
        
        if (sort & !is.null(groups)) {
            temp_medians <- aggregate(x@theta, list(groups), median, na.rm = TRUE)
            groups <- factor(groups, levels = temp_medians[order(temp_medians$x, decreasing = TRUE), 1])
        }
        
        theta <- lower <- upper <- NULL
        results <- data.frame(doclabels = doclabels, 
                              theta = x@theta, 
                              lower = x@theta - 1.96 * x@se.theta, 
                              upper = x@theta + 1.96 * x@se.theta)
        if (!is.null(groups))
            results$groups <- groups

        p <- if (sort) {
            ggplot(data = results, aes(x = reorder(doclabels, theta), y = theta))
        } else {
            ggplot(data = results, aes(x = doclabels, y = theta))
        }
        p <- p + 
            coord_flip() + 
            { if (!is.null(groups))
                facet_grid(as.factor(groups) ~ ., scales = "free_y", space = "free") } +       
            geom_pointrange(aes(ymin = lower, ymax = upper), lwd = .25, fatten = .4) + 
            geom_point(size = 1) +
            ylab("Estimated theta") + 
            xlab(NULL)
        

    } else {
        beta <- psi <- feature <- NULL
        results <- data.frame(feature = x@features, 
                              psi = x@psi,
                              beta = x@beta)
        p <- 
            ggplot(data = results,
                            aes(x = beta, y = psi, label = feature)) + 
            geom_text(colour = "grey70") +
            geom_text(aes(beta, psi, label = feature), 
                      data = results[results$feature %in% highlighted,],
                      color = highlighted_color) +
            xlab("Beta") +
            ylab("Psi") + 
            theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
    }
    
    # apply a minimal theme
    p <- p + 
        theme_bw() + 
        theme(panel.background = ggplot2::element_blank(),
              panel.grid.major.x = element_blank(),
              panel.grid.minor.x = element_blank(), 
              # panel.grid.major.y = element_blank(),
              panel.grid.minor.y = element_blank(), 
              plot.background = element_blank(),
              axis.ticks.y = element_blank(), 
              # panel.spacing = grid::unit(0.1, "lines"),
              panel.grid.major.y = element_line(linetype = "dotted"))
    
    suppressMessages(p)
}


