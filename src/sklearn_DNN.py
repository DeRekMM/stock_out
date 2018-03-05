import os
import time, datetime
import numpy as np
import pandas as pd
from sklearn import svm
from sklearn import preprocessing
from sklearn.neural_network import MLPClassifier
import sklearn.metrics 

import pickle
from sklearn.externals import joblib 


def rand_datasets(df, train_pct):
    rand_num = np.random.rand(len(df))
    
    df_train = df[rand_num < train_pct]
    df_cross = df[rand_num >= train_pct]
    
    return df_train, df_cross

#Geting data and change data type
data_dir = '/Users/derekwang/Work/Stock_out/Data/STOCK_OUT_master_training.csv'

data_raw = pd.read_csv(data_dir, sep=',', header=0)
data_clean = data_raw # outlier_remove(data_raw)


df_train, df_cross = rand_datasets(data_clean, 0.8)

train_features = df_train.iloc[:,3:-1]
X = train_features.values
train_labels = df_train['SIMPL_OOS_IND']
y = train_labels.values



test_features = df_cross.iloc[:,3:-1]
X_test = test_features.values
test_labels = df_cross['SIMPL_OOS_IND']
y_test = test_labels.values


scaler = preprocessing.StandardScaler()
scaler.fit(X)
X_train_scaled = scaler.transform(X)
X_test_scaled = scaler.transform(X_test)


summary = []

#Start training
for i in range(3,5):
    clf_dnn = MLPClassifier(alpha = .00001, hidden_layer_sizes = (64, 128, 64, 32, 16, 8), max_iter = i * 10)
    start_time = datetime.datetime.now().strftime('%H:%M:%S')
    print("start time is %s" %start_time)

    clf_dnn.fit(X_train_scaled,y)

    end_time = datetime.datetime.now().strftime('%H:%M:%S')
    print("end time is %s" % end_time)

#     joblib.dump(clf_dnn, 'clf.pkl')


    train_score = clf_dnn.score(X_train_scaled,y)
    print('train score is %s' % train_score)


    y_pred = clf_dnn.predict(X_train_scaled)

    #y_pred_df = pd.DataFrame(y_pred)
    #y_pred_df.to_csv('C:\\Users\\MXW6827\\Documents\\Work\\Truck Load Overage\\Models\\test\\Cross_val_prediction_1009.csv')


    f1_score = sklearn.metrics.f1_score(y, y_pred)
    print("F1 score on self is %s" % f1_score)
    recall_score = sklearn.metrics.recall_score(y, y_pred)
    print("Recall score on self is %s" % recall_score)
    precision_score = sklearn.metrics.precision_score(y, y_pred)
    print("Precision score on self is %s" % precision_score)

    test_score = clf_dnn.score(X_test_scaled,y_test)
    print ('test score is %s' % test_score)
    y_t_pred = clf_dnn.predict(X_test_scaled)
    t_f1_score = sklearn.metrics.f1_score(y_test, y_t_pred)
    print("F1 score on holdout is %s" % t_f1_score)
    t_recall_score = sklearn.metrics.recall_score(y_test, y_t_pred)
    print("Recall score on holdout is %s" % t_recall_score)
    t_precision_score = sklearn.metrics.precision_score(y_test, y_t_pred)
    print("Precision score on holdout is %s" % t_precision_score)
    
    summary .append([i * 10, train_score, f1_score, recall_score, precision_score, test_score, t_f1_score, t_recall_score, t_precision_score])

final_result = pd.DataFrame(data = summary, columns = ['Epochs','Train Score','Train F1','Train Recall', 'Train Precision', 'Test Score', 'Test F1', 'Test Recall', 'Test Precision'])
final_result.to_csv('/Users/derekwang/Work/Stock_out/Data/summary.csv')