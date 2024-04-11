### Developing

Contributions are welcome. To contribute, fork this repository, commit your changes and push them to your fork,
and submit a pull request explaining your contribution. Ideally, your changes will have a legible commit history.
To keep us informed about what you're doing, discuss your plans in a github issue here and refer it in your pull request.


### Worfklow

1. Edit code
2. Start a fresh R session with `R --vanilla` and run `devtools::check()` to test your changes. 
   - This also updates builds auto-generated documentation in the directory `man` based on your in-code Markdown. 
   - Syntax errors in that Markdown will be reported as warnings.
   - For example: square brackets must be escaped if meant literally. In Markdown, the unit interval is written \\[0,1\\].
3. Fix any errors or warnings reported by `devtools::check()`. 
   - If you think it is the tests and not the your changes that are in error, update the tests.
   - They're in the `tests/testthat` directory.
4. Commit your changes. 
   - In your commit message, explain what you've changed and why, including any problematic with tests.
   - Include in your commit any changes to the autogenerated documentation in the directory `man` and the file `NAMESPACE`. 
   - It is not necessary to merge changes to these files by hand, as they are autogenerated.

### Online Documentation
- The online documentation includes a function reference and a set of vignettes.
   - The function reference is based on the autogenerated man files.
   - The vignettes are based on RMarkdown files in the directory `vignettes`. 
- If you implement a new feature, it's helpful to explain how to use it in a vignette.
- The layout of the documentation, including a list of included vignettes, is defined in `_pkgdown.yml`.
- To check changes to the online documentation, you can render it locally using `pkgdown::build_site()`. 