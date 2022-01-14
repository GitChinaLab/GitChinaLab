#!/usr/bin/env bash

function retrieve_tests_metadata() {
  mkdir -p $(dirname "$KNAPSACK_RSPEC_SUITE_REPORT_PATH") $(dirname "$FLAKY_RSPEC_SUITE_REPORT_PATH") rspec_profiling/

  if [[ -n "${RETRIEVE_TESTS_METADATA_FROM_PAGES}" ]]; then
    if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
      curl --location -o "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "https://gitlab-org.gitlab.io/gitlab/${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
    fi

    if [[ ! -f "${FLAKY_RSPEC_SUITE_REPORT_PATH}" ]]; then
      curl --location -o "${FLAKY_RSPEC_SUITE_REPORT_PATH}" "https://gitlab-org.gitlab.io/gitlab/${FLAKY_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    fi
  else
    # ${CI_DEFAULT_BRANCH} might not be master in other forks but we want to
    # always target the canonical project here, so the branch must be hardcoded
    local project_path="gitlab-org/gitlab"
    local artifact_branch="master"
    local username="gitlab-bot"
    local job_name="update-tests-metadata"
    local test_metadata_job_id

    # Ruby
    test_metadata_job_id=$(scripts/api/get_job_id.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" -q "status=success" -q "ref=${artifact_branch}" -q "username=${username}" -Q "scope=success" --job-name "${job_name}")

    if [[ -n "${test_metadata_job_id}" ]]; then
      echo "test_metadata_job_id: ${test_metadata_job_id}"

      if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
        scripts/api/download_job_artifact.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" --job-id "${test_metadata_job_id}" --artifact-path "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
      fi

      if [[ ! -f "${FLAKY_RSPEC_SUITE_REPORT_PATH}" ]]; then
        scripts/api/download_job_artifact.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" --job-id "${test_metadata_job_id}" --artifact-path "${FLAKY_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
      fi
    else
      echo "test_metadata_job_id couldn't be found!"
      echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
      echo "{}" > "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    fi
  fi
}

function update_tests_metadata() {
  echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"

  scripts/merge-reports "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" knapsack/rspec*.json
  rm -f knapsack/rspec*.json

  export FLAKY_RSPEC_GENERATE_REPORT="true"
  scripts/merge-reports "${FLAKY_RSPEC_SUITE_REPORT_PATH}" rspec_flaky/all_*.json
  scripts/flaky_examples/prune-old-flaky-examples "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
  rm -f rspec_flaky/all_*.json rspec_flaky/new_*.json

  if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
    scripts/insert-rspec-profiling-data
  else
    echo "Not inserting profiling data as the pipeline is not a scheduled one."
  fi
}

function retrieve_tests_mapping() {
  mkdir -p $(dirname "$RSPEC_PACKED_TESTS_MAPPING_PATH")

  if [[ -n "${RETRIEVE_TESTS_METADATA_FROM_PAGES}" ]]; then
    if [[ ! -f "${RSPEC_PACKED_TESTS_MAPPING_PATH}" ]]; then
      (curl --location  -o "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" "https://gitlab-org.gitlab.io/gitlab/${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" && gzip -d "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz") || echo "{}" > "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
    fi
  else
    # ${CI_DEFAULT_BRANCH} might not be master in other forks but we want to
    # always target the canonical project here, so the branch must be hardcoded
    local project_path="gitlab-org/gitlab"
    local artifact_branch="master"
    local username="gitlab-bot"
    local job_name="update-tests-metadata"
    local test_metadata_with_mapping_job_id

    test_metadata_with_mapping_job_id=$(scripts/api/get_job_id.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" -q "status=success" -q "ref=${artifact_branch}" -q "username=${username}" -Q "scope=success" --job-name "${job_name}")

    if [[ -n "${test_metadata_with_mapping_job_id}" ]]; then
      echo "test_metadata_with_mapping_job_id: ${test_metadata_with_mapping_job_id}"

      if [[ ! -f "${RSPEC_PACKED_TESTS_MAPPING_PATH}" ]]; then
        (scripts/api/download_job_artifact.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" --job-id "${test_metadata_with_mapping_job_id}" --artifact-path "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" && gzip -d "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz") || echo "{}" > "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
      fi
    else
      echo "test_metadata_with_mapping_job_id couldn't be found!"
      echo "{}" > "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
    fi
  fi

  scripts/unpack-test-mapping "${RSPEC_PACKED_TESTS_MAPPING_PATH}" "${RSPEC_TESTS_MAPPING_PATH}"
}

function retrieve_frontend_fixtures_mapping() {
  mkdir -p $(dirname "$FRONTEND_FIXTURES_MAPPING_PATH")

  if [[ -n "${RETRIEVE_TESTS_METADATA_FROM_PAGES}" ]]; then
    if [[ ! -f "${FRONTEND_FIXTURES_MAPPING_PATH}" ]]; then
      (curl --location  -o "${FRONTEND_FIXTURES_MAPPING_PATH}" "https://gitlab-org.gitlab.io/gitlab/${FRONTEND_FIXTURES_MAPPING_PATH}") || echo "{}" > "${FRONTEND_FIXTURES_MAPPING_PATH}"
    fi
  else
    # ${CI_DEFAULT_BRANCH} might not be master in other forks but we want to
    # always target the canonical project here, so the branch must be hardcoded
    local project_path="gitlab-org/gitlab"
    local artifact_branch="master"
    local username="gitlab-bot"
    local job_name="generate-frontend-fixtures-mapping"
    local test_metadata_with_mapping_job_id

    test_metadata_with_mapping_job_id=$(scripts/api/get_job_id.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" -q "ref=${artifact_branch}" -q "username=${username}" -Q "scope=success" --job-name "${job_name}")

    if [[ $? -eq 0 ]] && [[ -n "${test_metadata_with_mapping_job_id}" ]]; then
      echo "test_metadata_with_mapping_job_id: ${test_metadata_with_mapping_job_id}"

      if [[ ! -f "${FRONTEND_FIXTURES_MAPPING_PATH}" ]]; then
        (scripts/api/download_job_artifact.rb --endpoint "https://gitlab.com/api/v4" --project "${project_path}" --job-id "${test_metadata_with_mapping_job_id}" --artifact-path "${FRONTEND_FIXTURES_MAPPING_PATH}") || echo "{}" > "${FRONTEND_FIXTURES_MAPPING_PATH}"
      fi
    else
      echo "test_metadata_with_mapping_job_id couldn't be found!"
      echo "{}" > "${FRONTEND_FIXTURES_MAPPING_PATH}"
    fi
  fi
}

function update_tests_mapping() {
  if ! crystalball_rspec_data_exists; then
    echo "No crystalball rspec data found."
    return 0
  fi

  scripts/generate-test-mapping "${RSPEC_TESTS_MAPPING_PATH}" crystalball/rspec*.yml
  scripts/pack-test-mapping "${RSPEC_TESTS_MAPPING_PATH}" "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  gzip "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  rm -f crystalball/rspec*.yml "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
}

function crystalball_rspec_data_exists() {
  compgen -G "crystalball/rspec*.yml" >/dev/null
}

function retrieve_previous_failed_tests() {
  local directory_for_output_reports="${1}"
  local rspec_pg_regex="${2}"
  local rspec_ee_pg_regex="${3}"
  local pipeline_report_path="test_results/previous/test_reports.json"

  # Used to query merge requests. This variable reflects where the merge request has been created
  local target_project_path="${CI_MERGE_REQUEST_PROJECT_PATH}"
  local instance_url="${CI_SERVER_URL}"

  echo 'Attempting to build pipeline test report...'

  scripts/pipeline_test_report_builder.rb --instance-base-url "${instance_url}" --target-project "${target_project_path}" --mr-id "${CI_MERGE_REQUEST_IID}" --output-file-path "${pipeline_report_path}"

  echo 'Generating failed tests lists...'

  scripts/failed_tests.rb --previous-tests-report-path "${pipeline_report_path}" --output-directory "${directory_for_output_reports}" --rspec-pg-regex "${rspec_pg_regex}" --rspec-ee-pg-regex "${rspec_ee_pg_regex}"
}

function rspec_simple_job() {
  local rspec_opts="${1}"

  export NO_KNAPSACK="1"

  eval "bin/rspec -Ispec -rspec_helper --color --format documentation --format RspecJunitFormatter --out junit_rspec.xml ${rspec_opts}"
}

function rspec_db_library_code() {
  local db_files="spec/lib/gitlab/database/"

  rspec_simple_job "-- ${db_files}"
}

function rspec_paralellized_job() {
  read -ra job_name <<< "${CI_JOB_NAME}"
  local test_tool="${job_name[0]}"
  local test_level="${job_name[1]}"
  local report_name=$(echo "${CI_JOB_NAME}" | sed -E 's|[/ ]|_|g') # e.g. 'rspec unit pg12 1/24' would become 'rspec_unit_pg12_1_24'
  local rspec_opts="${1}"
  local spec_folder_prefixes=""

  if [[ "${test_tool}" =~ "-ee" ]]; then
    spec_folder_prefixes="'ee/'"
  fi

  if [[ "${test_tool}" =~ "-jh" ]]; then
    spec_folder_prefixes="'jh/'"
  fi

  if [[ "${test_tool}" =~ "-all" ]]; then
    spec_folder_prefixes="['', 'ee/', 'jh/']"
  fi

  export KNAPSACK_LOG_LEVEL="debug"
  export KNAPSACK_REPORT_PATH="knapsack/${report_name}_report.json"

  # There's a bug where artifacts are sometimes not downloaded. Since specs can run without the Knapsack report, we can
  # handle the missing artifact gracefully here. See https://gitlab.com/gitlab-org/gitlab/-/issues/212349.
  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  cp "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "${KNAPSACK_REPORT_PATH}"

  if [[ -z "${KNAPSACK_TEST_FILE_PATTERN}" ]]; then
    pattern=$(ruby -r./tooling/quality/test_level.rb -e "puts Quality::TestLevel.new(${spec_folder_prefixes}).pattern(:${test_level})")
    export KNAPSACK_TEST_FILE_PATTERN="${pattern}"
  fi

  echo "KNAPSACK_TEST_FILE_PATTERN: ${KNAPSACK_TEST_FILE_PATTERN}"
  echo "SKIP_FLAKY_TESTS_AUTOMATICALLY: ${SKIP_FLAKY_TESTS_AUTOMATICALLY}"

  if [[ -d "ee/" ]]; then
    export KNAPSACK_GENERATE_REPORT="true"
    export FLAKY_RSPEC_GENERATE_REPORT="true"
    export SUITE_FLAKY_RSPEC_REPORT_PATH="${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    export FLAKY_RSPEC_REPORT_PATH="rspec_flaky/all_${report_name}_report.json"
    export NEW_FLAKY_RSPEC_REPORT_PATH="rspec_flaky/new_${report_name}_report.json"
    export SKIPPED_FLAKY_TESTS_REPORT_PATH="rspec_flaky/skipped_flaky_tests_${report_name}_report.txt"

    if [[ ! -f $FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${FLAKY_RSPEC_REPORT_PATH}"
    fi

    if [[ ! -f $NEW_FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${NEW_FLAKY_RSPEC_REPORT_PATH}"
    fi
  fi

  mkdir -p tmp/memory_test

  export MEMORY_TEST_PATH="tmp/memory_test/${report_name}_memory.csv"

  local rspec_args="-Ispec -rspec_helper --color --format documentation --format RspecJunitFormatter --out junit_rspec.xml ${rspec_opts}"

  if [[ -n $RSPEC_TESTS_MAPPING_ENABLED ]]; then
    tooling/bin/parallel_rspec --rspec_args "${rspec_args}" --filter "tmp/matching_tests.txt"
  else
    tooling/bin/parallel_rspec --rspec_args "${rspec_args}"
  fi

  date
}

function rspec_rerun_previous_failed_tests() {
  local test_file_count_threshold=${RSPEC_PREVIOUS_FAILED_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally exited because there are more than ${test_file_count_threshold} test files to rerun."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job "${test_files}"
  else
    echo "No failed test files to rerun"
  fi
}

function rspec_fail_fast() {
  local test_file_count_threshold=${RSPEC_FAIL_FAST_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally skipped because there are more than ${test_file_count_threshold} test files matched,"
    echo "which would take too long to run in this job."
    echo "All the tests would be run in other rspec jobs."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job "${rspec_opts} ${test_files}"
  else
    echo "No rspec fail-fast tests to run"
  fi
}

function rspec_matched_foss_tests() {
  local test_file_count_threshold=20
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally failed because there are more than ${test_file_count_threshold} FOSS test files matched,"
    echo "which would take too long to run in this job."
    echo "To reduce the likelihood of breaking FOSS pipelines,"
    echo "please add ~\"pipeline:run-as-if-foss\" label to the merge request and trigger a new pipeline."
    echo "This would run all as-if-foss jobs in this merge request"
    echo "and remove this failing job from the pipeline."
    exit 1
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job "${rspec_opts} ${test_files}"
  else
    echo "No impacted FOSS rspec tests to run"
  fi
}

function generate_frontend_fixtures_mapping() {
  local pattern=""

  if [[ -d "ee/" ]]; then
    pattern=",ee/"
  fi

  if [[ -d "jh/" ]]; then
    pattern="${pattern},jh/"
  fi

  if [[ -n "${pattern}" ]]; then
    pattern="{${pattern}}"
  fi

  pattern="${pattern}spec/frontend/fixtures/**/*.rb"

  export GENERATE_FRONTEND_FIXTURES_MAPPING="true"

  mkdir -p $(dirname "$FRONTEND_FIXTURES_MAPPING_PATH")

  rspec_simple_job "--pattern \"${pattern}\""
}
