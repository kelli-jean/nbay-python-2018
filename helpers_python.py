import pandas as pd
import numpy as np
from sklearn import model_selection, metrics   # Model selection and evaluation
from sklearn.model_selection import GridSearchCV   #For grid search parameter tuning
import matplotlib.pylab as plt

# From: https://www.analyticsvidhya.com/blog/2016/02/complete-guide-parameter-tuning-gradient-boosting-gbm-python/
def modelfit(alg, X, y, parameters, model_name,
             performCV=True, printFeatureImportance=True, cv_folds=5, logistic=False,
             output_folder='python_output'):

    # Standardize features for importance plot
    if logistic:
        X = X / np.std(X,0)

    if parameters:
        # Perform cross-validated grid search to find optimal model parameters
        grid = GridSearchCV(estimator=alg, param_grid=parameters, cv=cv_folds)
        grid.fit(X, y)
        alg = grid.best_estimator_
    else:
        #Fit the algorithm on the data
        alg.fit(X, y)

    #Predict training set:
    dtrain_predictions = alg.predict(X)
    dtrain_predprob = alg.predict_proba(X)[:,1]

    #Perform cross-validation:
    if performCV:
        cv_score = model_selection.cross_val_score(alg, X, y, cv=cv_folds, scoring='roc_auc')

    #Print model report:
    print("\nModel Report")
    #print("Accuracy : %.4g" % metrics.accuracy_score(y.values, dtrain_predictions))
    train_score = metrics.roc_auc_score(y, dtrain_predprob)
    print("AUC Score (Train): %f" % train_score)

    if performCV:
        avg_cv_score = np.mean(cv_score)
        std_cv_score = np.std(cv_score)
        min_cv_score = np.min(cv_score)
        max_cv_score = np.max(cv_score)
        print("CV Score : Mean - %.7g | Std - %.7g | Min - %.7g | Max - %.7g" % 
              (avg_cv_score, std_cv_score, min_cv_score, max_cv_score))
        
        scores = pd.DataFrame({'Train Score': [train_score], 'Avg CV Score': [avg_cv_score], 'Std': [std_cv_score], 'Min': [min_cv_score], 'Max': [max_cv_score]})
        scores.to_csv(output_folder + '/' + model_name + '_scores.csv', index=False)
        
    #Print Feature Importance:
    if printFeatureImportance:
        if not logistic:
            feat_imp = pd.Series(alg.feature_importances_, X.columns.values).sort_values(ascending=False)
        else:
            feat_imp = pd.Series(np.abs(alg.coef_[0]), X.columns.values).sort_values(ascending=False)
        feat_imp.to_csv(output_folder + '/' + model_name + '_feat_imp.csv')
        feat_imp.plot(kind='bar', title='Feature Importance')
        plt.ylabel('Feature Importance Score')
