{ lib
, fetchFromGitHub
, buildPythonPackage
, numpy
, cython
, scipy
, scikit-learn
, matplotlib
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "metric-learn";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "scikit-learn-contrib";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-IOMrXWZbnliSGgfTA7TNosQhQBFQEjZCHplVHt84dts=";
  };

  nativeBuildInputs = [ numpy cython ];
  propagatedBuildInputs = [ numpy scipy scikit-learn ];
  nativeCheckInputs = [ matplotlib pytestCheckHook ];

  # preCheck = ''
  #   # Remove the package in the build dir, because Python defaults to it and
  #   # ignores the one in Nix store with cythonized modules.
  #   rm -r metric_learn
  # '';
  doCheck = false;
  preCheck = ''
    export HOME=$(mktemp -d)
    cp -r $TMP/$sourceRoot/tests $HOME
    pushd $HOME
  '';
  postCheck = "popd";

  pytestFlagsArray = [ "--pyargs metric_learn" ];
  disabledTestPaths = [
    "benchmarks"
    "examples"
    "doc"
  ];
  disabledTests = [
    "build"   # needs network connection
    "test_all_estimators" # sklearn.exceptions.NotFittedError: Estimator fails to pass `check_is_fitted` even though it has been fit.
  ];

  # Check packages with cythonized modules
  pythonImportsCheck = [
    "metric_learn"
  ];

  # meta = {
  #   description = "A set of tools for scikit-learn";
  #   homepage = "https://github.com/scikit-learn-contrib/scikit-learn-extra";
  #   license = lib.licenses.bsd3;
  #   maintainers = with lib.maintainers; [ yl3dy ];
  # };
}
