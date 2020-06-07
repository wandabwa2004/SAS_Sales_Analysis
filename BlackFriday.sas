%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '/folders/myfolders/BlackFriday.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.BFriday;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.BFriday; RUN;


/*%web_open_table(WORK.IMPORT);

/*PRESENTATION 1. INTRODUCTION - METHODOLOGY*/
TITLE "Exploration of  Black Friday Data";
PROC CONTENTS DATA = WORK.bfriday;
RUN;

/*OBSERVATIONS*/
PROC PRINT DATA=WORK.BFriday (OBS=2) NOOBS LABEL ; RUN; 


TITLE "Null Values in all variables";
/* CREATE A FORMAT TO GROUP MISSING AND NONMISSING */
PROC FORMAT;
 VALUE $MISSFMT ' '='MISSING' OTHER='NOT MISSING';
 VALUE  MISSFMT  . ='MISSING' OTHER='NOT MISSING';
RUN;

PROC FREQ DATA=WORK.BFriday; 
FORMAT _CHAR_ $MISSFMT.; /* APPLY FORMAT FOR THE DURATION OF THIS PROC */
TABLES _CHAR_ / MISSING MISSPRINT NOCUM NOPERCENT;
FORMAT _NUMERIC_ MISSFMT.;
TABLES _NUMERIC_ / MISSING MISSPRINT NOCUM NOPERCENT;
RUN;


/*UNIVARIATE ANALYSIS*/
DATA WORK.CLEAN;
SET WORK.BFriday;
DROP PRODUCT_CATEGORY_3

RETAIN _PRODUCT_CATEGORY_2;

IF NOT MISSING(PRODUCT_CATEGORY_2) THEN _PRODUCT_CATEGORY_2=PRODUCT_CATEGORY_2;
ELSE PRODUCT_CATEGORY_2=PRODUCT_CATEGORY_1;
DROP _PRODUCT_CATEGORY_2;
RUN;


/*concatenate  two product categories*/
DATA TEST;
SET Work.clean;
DIST_PROD = CATX('-',PRODUCT_CATEGORY_1, PRODUCT_CATEGORY_2);
RUN;

/*Distribution of Purchases as Histogram*/
PROC SGPLOT DATA = TEST;
TITLE "Distribution of Purchases";
FOOTNOTE "Created by Herman Wandabwa";
HISTOGRAM PURCHASE /NBINS =20;
DENSITY PURCHASE / TYPE = KERNEL;
RUN;


/* define 'threepanel' template that displays a histogram, box plot, and Q-Q plot */
proc template;
define statgraph threepanel;
dynamic _X _QUANTILE _Title _mu _sigma;
begingraph;
   entrytitle halign=center _Title;
   layout lattice / rowdatarange=data columndatarange=union 
      columns=1 rowgutter=5 rowweights=(0.4 0.10 0.5);
      layout overlay;
         histogram   _X / name='Histogram' binaxis=false;
         densityplot _X / name='Normal' normal();
         densityplot _X / name='Kernel' kernel() lineattrs=GraphData2(thickness=2 );
         discretelegend 'Normal' 'Kernel' / border=true halign=right valign=top location=inside across=1;
      endlayout;
      layout overlay;
         boxplot y=_X / boxwidth=0.8 orient=horizontal;
      endlayout;
      layout overlay;
         scatterplot x=_X y=_QUANTILE;
         lineparm x=_mu y=0.0 slope=eval(1./_sigma) / extend=true clip=true;
      endlayout;
      columnaxes;
         columnaxis;
      endcolumnaxes;
   endlayout;
endgraph;
end;
run;



/* Macro to create a three-panel display that shows the 
   distribution of data and compares the distribution to a normal
   distribution. The arguments are 
   DSName = name of SAS data set
   Var    = name of variable in the data set.
   The macro calls the SGRENDER procedure to produce a plot
   that is defined by the 'threepanel' template. The plot includes
   1) A histogram with a normal and kernel density overlay
   2) A box plot
   3) A normal Q-Q plot

   Example calling sequence:
   ods graphics on;
   %ThreePanel(sashelp.cars, MPG_City)
   %ThreePanel(sashelp.iris, SepalLength)

   For details, see
   http://blogs.sas.com/content/iml/2013/05/08/three-panel-visualization/
*/
%macro ThreePanel(DSName, Var);
   %local mu sigma;

   /* 1. sort copy of data */
   proc sort data=&DSName out=_MyData(keep=&Var);
      by &Var;
   run;

   /* 2. Use PROC UNIVARIATE to create Q-Q plot 
         and parameter estimates */
   ods exclude all;
   proc univariate data=_MyData;
      var &Var;
      histogram &Var / normal; /* create ParameterEstimates table */
      qqplot    &Var / normal; 
      ods output ParameterEstimates=_PE QQPlot=_QQ(keep=Quantile Data rename=(Data=&Var));
   run;
   ods exclude none;

   /* 3. Merge quantiles with data */
   data _MyData;
   merge _MyData _QQ;
   label Quantile = "Normal Quantile";
   run;

   /* 4. Get parameter estimates into macro vars */
   data _null_;
   set _PE;
   if Symbol="Mu"    then call symputx("mu", Estimate);
   if Symbol="Sigma" then call symputx("sigma", Estimate);
   run;

   proc sgrender data=_MyData template=threepanel;
   dynamic _X="&Var" _QUANTILE="Quantile" _mu="&mu" _sigma="&sigma"
          _title=" &Var Distribution";
   run;
%mend;

ODS GRAPHICS ON;
%THREEPANEL(WORK.TEST, PURCHASE)

/*Age  Distribution*/
ODS GRAPHICS ON;
%THREEPANEL(WORK.TEST, Age)


/*Distribution of Purchases as Histogram*/
PROC SGPLOT DATA = TEST;
TITLE "Marital Status Distribution of  Buyers - 1 for  Married and  0 for  Unmarried";
FOOTNOTE "Created by Herman Wandabwa";
HISTOGRAM Marital_Status /NBINS =20;
DENSITY Marital_Status / TYPE = KERNEL;
RUN;

/*PRODUCT DISTRIBUTION*/
/*CREATE A TABLE AGGREGATED BY DISTINCT PRODUCT COUNTS*/
PROC SQL;
CREATE TABLE PROD_DISTR AS
SELECT DIST_PROD, 
	   COUNT(DISTINCT USER_ID)AS NUMBER_OF_CUST, 
	   SUM(PURCHASE) AS TOTAL_SALES,
	   AVG(PURCHASE) AS AVG_SALES,
	   CITY_CATEGORY
FROM TEST
GROUP BY DIST_PROD, CITY_CATEGORY
;
QUIT;

/*SLIDE 9 PURCHASE DISTRIBUTION BOX PLOT*/
PROC SGPLOT DATA = PROD_DISTR;
TITLE "Average sales per product/ City";
FOOTNOTE "Herman Wandabwa- Reporting";
VBOX AVG_SALES / GROUP = CITY_CATEGORY GROUPDISPLAY=CLUSTER ;

RUN;
QUIT;

/*Distribution of Customers*/

PROC TABULATE DATA=TEST;
TITLE 'Customers Distribution Across Age, City Category, Gender and  Marital Status';
FOOTNOTE "Herman Wandabwa- Reporting";
CLASS AGE CITY_CATEGORY GENDER Marital_Status;

TABLE CITY_CATEGORY*(GENDER ALL), AGE='AGE GROUPS'*(PCTN='% ') ALL*(N PCTN) Marital_Status;
RUN;


/*PART 1 BAR CHART*/
PROC SGPLOT DATA = TEST;
TITLE "Customers by Gender";
FOOTNOTE "Herman Wandabwa- Reporting";
VBAR CITY_CATEGORY / GROUP = GENDER GROUPDISPLAY=CLUSTER ;

RUN;

ODS LISTING STYLE=LISTING;
ODS GRAPHICS / WIDTH=5IN HEIGHT=2.81IN;

TITLE 'TOP PRODUCT SALES BY NUMBER OF CUSTOMERS IN CITY CATEGORIES';
PROC SGPLOT DATA=PROD_DISTR(WHERE =(DIST_PROD = '1-15' OR DIST_PROD = '1-2' 
									OR DIST_PROD = '5-5' OR DIST_PROD = '5-8'
									OR DIST_PROD = '8-8'OR DIST_PROD = '6-8'));
  VBAR CITY_CATEGORY / RESPONSE=NUMBER_OF_CUST GROUP=DIST_PROD GROUPDISPLAY=CLUSTER 
    STAT=MEAN DATASKIN=GLOSS;
  XAXIS DISPLAY=(NOLABEL NOTICKS);
  YAXIS GRID;
RUN;


/*Descritive Statistics*/
PROC UNIVARIATE DATA=TEST;
  CLASS MARITAL_STATUS;
  VAR PURCHASE;      /* COMPUTES DESCRIPTIVE STATISITCS */
  HISTOGRAM PURCHASE / NORMAL MIDPOINTS=(250 TO 25000 BY 2500) NROWS=2 ODSTITLE="PURCHASE DISTRIBUTION BY MARITAL STATUS";
  ODS SELECT HISTOGRAM; /* DISPLAY ON THE HISTOGRAMS */
RUN;
QUIT;


/*Customer Segmentation*/

PROC TABULATE DATA=TEST;
TITLE 'CUSTOMER PROFILE BY FEATUE SIGNIFICANCE';
CLASS CITY_CATEGORY GENDER;
VAR TOTAL_AMT;
TABLE CITY_CATEGORY ALL ,GENDER *(TOTAL_CUST=' ');
RUN;

PROC SQL;
CREATE TABLE UNQ_CUST AS
SELECT DISTINCT USER_ID,
				GENDER,
				AGE,
				OCCUPATION,
				MARITAL_STATUS,
				CITY_CATEGORY,
				STAY_IN_CURRENT_CITY_YEARS
FROM TEST
;

PROC SQL;
CREATE TABLE CUST_PUR AS
SELECT USER_ID, 
	   SUM(PURCHASE) AS TOTAL_AMT,
	   COUNT(PRODUCT_CATEGORY_1) AS TOTAL_PRODS
FROM TEST
GROUP BY USER_ID;


PROC SQL;
CREATE TABLE AGGRE AS
SELECT *
FROM CUST_PUR C
JOIN UNQ_CUST U
ON C.USER_ID = U.USER_ID;
QUIT;

PROC TABULATE DATA=AGGRE;
TITLE 'Profiles of  Customers';
FOOTNOTE "Herman Wandabwa- Reporting";
CLASS AGE CITY_CATEGORY GENDER;
VAR TOTAL_AMT;
TABLE (CITY_CATEGORY ALL)*(GENDER ALL), AGE='AGE GROUPS'*(PCTN='% ') ALL*(N PCTN);
RUN;

/*CUSTOMER WISE PURCHASE*/
ODS GRAPHICS ON;
%THREEPANEL(WORK.AGGRE, TOTAL_AMT)


TITLE 'Total Sales by Product and  City';
FOOTNOTE "Herman Wandabwa- Reporting";
PROC SGPLOT DATA=PROD_DISTR(WHERE =(DIST_PROD = '1-15' OR DIST_PROD = '1-2' 
									OR DIST_PROD = '5-5' OR DIST_PROD = '5-8'
									OR DIST_PROD = '8-8'OR DIST_PROD = '6-8'));
  VBAR CITY_CATEGORY / RESPONSE=TOTAL_SALES GROUP=DIST_PROD GROUPDISPLAY=CLUSTER 
    STAT=SUM DATASKIN=GLOSS;
  XAXIS DISPLAY=(NOLABEL NOTICKS);
  YAXIS GRID;
RUN;


PROC UNIVARIATE DATA=AGGRE;
  CLASS CITY_CATEGORY;
  VAR TOTAL_AMT;      
  HISTOGRAM TOTAL_AMT / NROWS=3 ODSTITLE="Total Amount Spent  by City Category";
  FOOTNOTE "Herman Wandabwa- Reporting";
  ODS SELECT HISTOGRAM; /* DISPLAY ON THE HISTOGRAMS */
RUN;


