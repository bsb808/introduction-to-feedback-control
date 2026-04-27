Now I want to reoganize the entire project. The structure I envision is both a class and a book where each week of class is a chapter of the book.  I'd like to rearrange the repository for this and put everything else in a "misc" folder (put the exams there).   Here is the list of weeks/chapters and the status of each.  
1. Laplace Transforms Part 1 :: Not yet started, placeholder
2. Laplace Transforms Part 2 and Modeling :: nothing started other than a handle 
3. Lab: USV System Identification :: Complete draft in labs_usv/lab1_sysid  
4. Time Response: In "hw3_timeresponse" there is some material for the assignments and explanatory diagrams (maybe)
5. Block diagrams and PID feedback :: We will need to refactor the pid_article so that portions of it go here and portions of it go into following weeks.   Create a to-do list as a markdown file in the root directory of the repo and append this item to the list. There is some material in hw4_blockdiagrms for the assignment.   You can delete the pdf if the refs directory and the pdf in the images directory. 
6. Steady state error :: There is a comlete draft of the chapter in hw5_steadystateerror/sse_article.tex.  There assignment is in hw5_25_1.tex
7. Lab: USV PID Tuning: Surge and Yaw :: Not yet started
8. Frequency Response: Part 1
9. Frequency Resposne: Part 2
10. Lab: USV Navigation Tuning



- I'd like to have each week/chapter both as a standalone document and as a chapter that can be built from the root directory.
- Each week/chaater contains the following:
-- stand alone assignment
-- example code
-- stand alone chapter, which has code for generating figures
-- "refs" folder for references

-------------------------------------


I'd like to start working on each chapter/week one at a time.   Each week there is a ~10 Mb reference PDF and images.  To use our time most efficiently (token use, etc.), is it better to do this in one long session or to break it up into a separate claude session for each chapter/week?

-------------------------------------

Week 1: Laplace Part 1.

The starting point is the reference in the refs directory. 

Worthwile mentioning that we (over)use the word "system" and it is a catch all for the idea modeling physical (real) things as a set of definable inputs and definable outputs.   All models are wrong, but this one is useful.  This abstraction has proven very useful for engineering complex capabilites.

I'll do the touchy-feely overview in person class with slides and videos.  This is the concrete material they need without the fuss.  This chapter is just the math for engineers of laplace transforms.   It is motivated by the argument that this is they mathematical tool to be able to speak (one of) the languages of control.  

Laplace is treated just an abstract method for solving differntial equations from 300 years ago that is useful for designign feedback systems.  Content goes from the tables of common laplace transforms and theorems through inverse laplace with partial fractions.   We mention that there is an integral definition, but that the tables can be taken as standalone.   They are also not to be memorized, but they will probably will be by the end of the course.  

The inverse laplace is treated as a consceptual process needed to solve an ODE.  We mention that ODEs are the quitessential example of the quote "all models are wrong, but some are useful"   We use MATLAB as a calculator for the algebra.   I use the `residue` method in matlab.  I like that this connects them to the idea of poles and zeros as part of the ODE (a useful model of the dynamics of the things we want to control and how we control them).  It feels antiquted, so maybe there is a better demonstration.  

I build solving odes and inverse laplace together
First order systems: solving a simple ode (still just math) with laplace and inverse laplace. Example is usually first order ODE with constant input.  I present this is a step by step process: take the laplace of the entire ODE, algebraically rarrange ("solving in the laplace domain"), take the inverse laplace.   Note that it would be nice if there was a theorem in our table for the laplace transform of product of two functions being the product of the laplace of each (show an expression with a not equal), but that isn't allowed, so we have to write it in a form we can use the tables, hence partial fraction expansion. 
pdftk ControlSystemsEngineering7thEditionbyNise-1.pdf cat 355-400 output nise_laplace.pdf 

(The last part of this material we  address in the next week, but I think it should conceptually go here. )
Second order systems:  Apply the same process to a second order ODE.  When MATLAB produces imaginary or complex poles, how is that interpreted so that we can write the parital fraction expansion form and use the tables. 

Summary is we've turned solving (specific kinds of) ODEs into algebra.

Include worked examples.  The assigment exercises go in a stand alone document. 

---------------
Let's start working on chapter/week 2. 

Week 2: Modeling

Starting point is in refs.  The PDF files are the material and the equations and figures are jpg files 

We start with the transfer function.  Emphasize this is the "system" abstraction of input and output mentioned last week.  In my opinion the standard forms in the refs are way to complicated.  I prefer to work a few examples to see the pattern and then show a simplified general form.  Simple math examples of given an ODE (and which variables are inputs or outputs) the process of generating the transfer function is straightforward and similar to what we did in week, but without the partial fraction expansion.  We aren't intersted in how the system response to anything other than the inputs we defined in our "system" model. 

For modeling we stick to very simple mechanical lumped parameter models, tranlation and rotation.  One degree of freedom only to limit our scope. For the USV example we'll do in lab, this is sufficient.  The students have many classes (statics, dynamics, circuits) that focus on modeling.  I'd argue much of engineering is using the models, abstractions, to aid our understanding for the purposes of improving thigs.  So we don't need to focus too much on how to create models, just that we'll need a model of the system we are trying to control and how that model is developed is specific to the domaing, e.g., surface ships, underwater, fixed-wing, rotor wind, space all have domain specific methods of modeling the dynamics of the plant.  

For modeling, I'd prefer an alternative term to "impedence" for the constiuetive relationships.  I think if it more as the conceptual models being expressed in the time domain for the laplace domain (we don't call it the frequency domain until we get to frequency response.)

Put it on our TODO.md list to add examples and/or assignment exercises for the usv.

Start the assignment with simple math examples of given an ODEs.  Add anything else that is you find.


------------------------------

Week 4: Time response

The starting point is the PDF in the reference in the refs directory. The images are figures, tables and equations from the PDF.

We again take an engineering-first approach to this set of mathematical anaysis tools.  We focus on the canonical time response for first and second order models, specifically the step response and use the impulse response to illustrate the math (the algebra is more transparent for an impluse response).  We make the case that these are the "building blocks" of more complex dynamics and that because of Laplace we can split complex dynamics into concatenations of building blocks: constants, differentiation/integration, first order and second order blocks.

We emphasize the standard/canonical form of each and how that can allow us to immediately recognize "system parameters" - which encode the physical dynamics (physical parameters) in a general way.
First order system
$G_1(s) = \frac{K_{\mathrm{dc}}}{\tau \, s + 1} = K_{\mathrm{dc}} \frac{a}{s+a}$
The two forms emphasize diffetent things.  First is aids in time response interpretation with the time constant.  The second emphasizes the laplace domain pole intterpretation.   For first order there are two system parameters for the time domain: DC gain and time constant.

Second order - we often implicity mean "underdamped" here.
$K_dc\frac{omega_n^2}{s^2 + 2 \zeta \omega_n s + \omega_n^2} = G_2(s) = K_dc \frac{(script R for real)^2 + (script I for imaginare)^2}{(s+R)^2+(I)^2} =  K_dc \frac{(\zeta \omega_n)^2 + )\omega_d)^2}{(s+\zeta \omega_n)^2 + \omega_d^2}$
There are two forms here, the first is useful for identifying the system parmaters from a TF, the second emphasizes that for underdamped systems the poles have a real an imaginary part and those parts map to time resopnse: the exponential decaying envelope (like we say with first order) and imaginar part maps to the speed of the sinusoids (and the resulting "speed" of the transient response)

I like visuals like figure 4.11 to emphasize a theme: These tools are all different "views" we can use to build understanding an intuition about the dynamics of the feedback system - both the dynamics of the thing we are controlling (the plant) and the dynamics of the controllers we are designing.  The views we have so far are ODEs (governing equations for the model), transfer function ("system" input output model in laplace domain), pole zero map (visual representation in laplace domain) and time response (both the time domain math expression and the plot)

For performance metrics, we emphasize the transient metrics as the language of specifing the speed of the system.  Calculating of the rise time for a second order model is always tricky in the reference.  I'd like to mention this complex way, but also use a simplified approximation.  I think that approximation is somethink like "rise time is $1.8/\omega_n$ for $0.1<\zeta<0.9$, but CLAUDE should look this up to get it correct.  Keep the deriviations of the metrics brief.  We want to show that these come directly from the math, but dont need to rehash the derivations.  Retain the bit about "Second-Order Transfer Functions via Testing", but make it more general to say that these metrics have definitions that do not rely on any kind of model and can be generated anayitcally for our LTI models, generated numerically for more complex non-linear models or measured experimentally for real systems.

Can leave out most of "System Response with Additional Poles" and just say that with MATLAB (or other computing help) we can use the computer to generate the time response and metrics from higher order systems, but don't need to do the math.  Doing the math for these simple building blocks is worth the return in intuition/insight.

Skip "System Response with Zeros" for now.   Note that these metrics are specific only for the canonical/standard froms for first and second order models with no zeros or additional poles.

Skip completely "4.9 Effects of Nonlinearities upon Time Response" and "4.10 Laplace Transform Solution of State Equations" and "4.11 Time Domain Solution of State Equations:"

The assignment is in good shape, but please review.

Generate the matlab examples as a standalone companion script.


------------------------------

Week 8: Frequency Response part 1

The starting point is the PDF in the reference in the refs directory. The images are figures, tables and equations from the PDF.

I approach the material with two goals to communication: the concept frequency response is analogous to time response.  Both are analytical abstractions that we use to approximate the dynamics of real phenomena.  The time domain is more readily relatable as we are used to thinking about temporal cause and effect.  The frequency domain is more subtle and abstract, but equally useful. The second goal is very pragmatic - the basics of how to sketch the anatomy of the Bode plot for simple systems.   Students do sketch Bode plots by hand in the class. The rational for this is that learning to sketch this "view" of the system helps to understand the anatomy of the Bode plot (what features of the dynamics are being communicated) and the process is simple enough to make the benefit worth the effort. 

I teach builing the Bode sketch as an algorithmic process of breaking the transfer function down into the building block Bode form, sketching each block and then visually summing them.  This online tool does an excellent job of presenting this as a step by step process: https://lpsa.swarthmore.edu/Bode/BodeRules.html

Don't bother with the "Corrections to Second-Order Bode Plots".   The sketches are learning tools.  We compare them to MATLAB plots, but we know we'll always have computer tools (or data) to actually visualize the frequency response.

I do mention that the frequency response can be measured experimentally for a variety of situations.  Just like our language for characterizing and communicating the time response, the "Bode plot" is the language of the frequency response "view".

Skip all the content after "Corrections to Second-Order Bode Plots" in the PDF.  We'll cover that later. 

Put all the MATLAB in a standalone .m script.  No code in the chapter. 

The sketchbode.m utility is a tool  a student of mine wrote around 2006 to visualize both the asymptotic (straight line) approximation and the actual frequency response. 

------------------------------------

I'm going to go ahead and do the draft of week08 frequency response part 2 here as well.  The strting point is in the refs directory.  two PDFs with content and the images, equations and table are in included as image files. 

The material covered includes
 "10.7 Stability, Gain Margin, and Phase Margin
via Bode Plots" :  We do not discuss Nyquist, only present the stability criteria as given truth that is named the Nyquist criteria (I have a handwavy conceptual analogy I go through in class. )
* "10.8 Relation Between Closed-Loop Transient
and Closed-Loop Frequency Responses" : Connecing the various "views" of model dynamics by showing some equivalences between time domain and frequency domain language.
* "10.10 Relation Between Closed-Loop Transient
and Open-Loop Frequency Responses" : 10.8 and 10.10 might be combined or at least linked. 
* " 11.1 Introduction"
* "11.2 Transient Response via Gain Adjustment" - Connected to gain and phase margin.  This is as far as we go, just being able to select a proportional gain value.

