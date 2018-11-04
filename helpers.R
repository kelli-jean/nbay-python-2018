
# Helpers for dog_report.Rmd

group_zip_code = function(zip_code) {
  # Returns the first 3 digits of a zip code
  # 
  # Args
  # ----
  # zip_code: int or character, should have more that 3 digits/letters
  #
  # Returns
  # -------
  # First 3 digits/letters
  #
  return(substr(zip_code, 1, 3))
}



plot_categorical = function(dogs, column_name, 
                            plot_title, n=10, ylimits=c(0,1),
                            factor_order = NA){
  # Returns average spayed/neutered rate for each factor level, with 95% confidence bars
  #
  # Args
  # ----
  # dogs: data.frame of the dogs
  # 
  # column_name: character, name of the categorical column to group by
  #
  # plot_title: character, title for plot
  #
  # n: top n levels will be plotted
  # 
  # ylimits: y-axis limits for the plot
  #
  # factor_order: order in which the levels will be plotted. 
  #   If NA, will order based on number of records for each level. 
  #
  # Returns
  # -------
  # ggplot of the spayed/neutered rate and corresponding grouped data as a 
  # tibble 
  
  dogs$group = dogs[,column_name]
  dogs_by_group = dogs %>%
    group_by(group) %>%
    summarise(n_dogs = length(spayed_or_neutered), 
              spayed_or_neutered_rate = mean(spayed_or_neutered_bool)) %>%
    arrange(desc(n_dogs))
  
  tot_dogs = nrow(dogs)
  
  se = with(dogs_by_group, sqrt(spayed_or_neutered_rate * (1-spayed_or_neutered_rate)/n_dogs))
  z_score = qnorm(0.975)
  dogs_by_group$lower = pmax(0, dogs_by_group$spayed_or_neutered_rate - se * z_score)
  dogs_by_group$upper = pmin(1, dogs_by_group$spayed_or_neutered_rate + se * z_score)
  dogs_by_group$perc_dogs = dogs_by_group$n_dogs / tot_dogs
  
  if (is.na(factor_order[1])){
    factor_order = rev(dogs_by_group$group)
  }
  dogs_by_group$group = factor(dogs_by_group$group,
                               levels=factor_order,
                               ordered=TRUE)
  
  p1 = head(dogs_by_group, n=n) %>%
    ggplot(aes(x=group, y=spayed_or_neutered_rate)) + 
    geom_point() + 
    geom_errorbar(aes(ymin=lower, ymax=upper)) + 
    theme_classic() + 
    expand_limits(y=ylimits) +
    xlab(NULL) + 
    ylab("Spayed/Neutered Rate") + 
    scale_y_continuous(label=percent) + 
    coord_flip() + 
    ggtitle(plot_title)
  
  p2 = head(dogs_by_group, n=n) %>%
    ggplot(aes(x=group, y=n_dogs)) + 
    geom_point() + 
    theme_classic() + 
    xlab(NULL) + 
    ylab("Number of Dogs") + 
    scale_y_continuous(label=comma) + 
    coord_flip() + 
    theme(axis.text.y=element_blank()) + 
    ggtitle(" ") 
  
  names(dogs_by_group)[names(dogs_by_group) == "group"] = column_name
  return(list(df = dogs_by_group, plot=plot_grid(p1, p2)))
}
