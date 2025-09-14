#!/bin/bash

# Sunbreak Test Runner Script
# This script runs the complete test suite for the Sunbreak iOS app

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Sunbreak.xcodeproj"
SCHEME_TESTS="SunbreakTests"
SCHEME_UI_TESTS="SunbreakUITests"
SIMULATOR_DEVICE="iPhone 15"
SIMULATOR_OS="iOS 17.4"

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if project exists
if [ ! -f "$PROJECT_NAME" ]; then
    print_error "Project file $PROJECT_NAME not found!"
    exit 1
fi

# Parse command line arguments
RUN_UNIT_TESTS=true
RUN_UI_TESTS=true
RUN_PERFORMANCE_TESTS=true
DEVICE_ONLY=false
CLEAN_BUILD=false
VERBOSE=false
COVERAGE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_UI_TESTS=false
            RUN_PERFORMANCE_TESTS=false
            shift
            ;;
        --ui-only)
            RUN_UNIT_TESTS=false
            RUN_PERFORMANCE_TESTS=false
            shift
            ;;
        --performance-only)
            RUN_UNIT_TESTS=false
            RUN_UI_TESTS=false
            shift
            ;;
        --device-only)
            DEVICE_ONLY=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --help)
            echo "Sunbreak Test Runner"
            echo ""
            echo "Usage: ./run_tests.sh [options]"
            echo ""
            echo "Options:"
            echo "  --unit-only        Run only unit tests"
            echo "  --ui-only          Run only UI tests"
            echo "  --performance-only Run only performance tests"
            echo "  --device-only      Run tests on device only (requires connected device)"
            echo "  --clean            Clean build before testing"
            echo "  --verbose          Show detailed output"
            echo "  --coverage         Generate code coverage report"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./run_tests.sh                    # Run all tests"
            echo "  ./run_tests.sh --unit-only       # Run only unit tests"
            echo "  ./run_tests.sh --coverage        # Run with coverage report"
            echo "  ./run_tests.sh --device-only     # Run on connected device"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_header "SUNBREAK TEST SUITE"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_info "Cleaning build..."
    xcodebuild clean -project "$PROJECT_NAME" -scheme "$SCHEME_TESTS" > /dev/null 2>&1
    print_success "Clean completed"
fi

# Determine destination
if [ "$DEVICE_ONLY" = true ]; then
    # Try to find connected device
    DEVICE_ID=$(xcrun xctrace list devices | grep "iPhone" | grep -v "Simulator" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/')
    if [ -z "$DEVICE_ID" ]; then
        print_error "No connected iPhone found for device testing"
        print_info "Connect an iPhone and ensure it's trusted, then try again"
        exit 1
    fi
    DESTINATION="platform=iOS,id=$DEVICE_ID"
    print_info "Running tests on device: $DEVICE_ID"
else
    DESTINATION="platform=iOS Simulator,name=$SIMULATOR_DEVICE,OS=$SIMULATOR_OS"
    print_info "Running tests on simulator: $SIMULATOR_DEVICE"
fi

# Build test options
TEST_OPTIONS=""
if [ "$VERBOSE" = true ]; then
    TEST_OPTIONS="$TEST_OPTIONS -verbose"
fi

if [ "$COVERAGE" = true ]; then
    TEST_OPTIONS="$TEST_OPTIONS -enableCodeCoverage YES"
fi

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Run Unit Tests
if [ "$RUN_UNIT_TESTS" = true ]; then
    print_header "RUNNING UNIT TESTS"
    
    print_info "Building test target..."
    if xcodebuild build-for-testing \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_TESTS" \
        -destination "$DESTINATION" \
        > build_unit.log 2>&1; then
        print_success "Unit test build completed"
    else
        print_error "Unit test build failed"
        if [ "$VERBOSE" = true ]; then
            cat build_unit.log
        fi
        exit 1
    fi
    
    print_info "Running unit tests..."
    if xcodebuild test-without-building \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_TESTS" \
        -destination "$DESTINATION" \
        $TEST_OPTIONS \
        > unit_tests.log 2>&1; then
        print_success "Unit tests passed"
        UNIT_TEST_COUNT=$(grep -c "Test Case.*passed" unit_tests.log || echo "0")
        TOTAL_TESTS=$((TOTAL_TESTS + UNIT_TEST_COUNT))
        PASSED_TESTS=$((PASSED_TESTS + UNIT_TEST_COUNT))
    else
        print_error "Unit tests failed"
        UNIT_TEST_FAILURES=$(grep -c "Test Case.*failed" unit_tests.log || echo "0")
        UNIT_TEST_COUNT=$(grep -c "Test Case.*\(passed\|failed\)" unit_tests.log || echo "0")
        TOTAL_TESTS=$((TOTAL_TESTS + UNIT_TEST_COUNT))
        FAILED_TESTS=$((FAILED_TESTS + UNIT_TEST_FAILURES))
        PASSED_TESTS=$((PASSED_TESTS + UNIT_TEST_COUNT - UNIT_TEST_FAILURES))
        
        if [ "$VERBOSE" = true ]; then
            cat unit_tests.log
        else
            echo "Failed tests:"
            grep "Test Case.*failed" unit_tests.log || echo "No specific failures found"
        fi
    fi
    
    echo ""
fi

# Run Performance Tests (subset of unit tests)
if [ "$RUN_PERFORMANCE_TESTS" = true ]; then
    print_header "RUNNING PERFORMANCE TESTS"
    
    print_info "Running performance benchmarks..."
    if xcodebuild test \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_TESTS" \
        -destination "$DESTINATION" \
        -only-testing:SunbreakTests/PerformanceTests \
        $TEST_OPTIONS \
        > performance_tests.log 2>&1; then
        print_success "Performance tests completed"
    else
        print_warning "Some performance tests may have failed"
        if [ "$VERBOSE" = true ]; then
            cat performance_tests.log
        fi
    fi
    
    # Extract performance metrics
    if [ -f "performance_tests.log" ]; then
        print_info "Performance Results:"
        grep "Time:" performance_tests.log | head -5 || echo "No timing data found"
        grep "Memory:" performance_tests.log | head -3 || echo "No memory data found"
    fi
    
    echo ""
fi

# Run UI Tests
if [ "$RUN_UI_TESTS" = true ]; then
    print_header "RUNNING UI TESTS"
    
    if [ "$DEVICE_ONLY" = false ]; then
        print_warning "UI tests work best on physical devices for Screen Time API testing"
        print_info "Consider using --device-only flag for more accurate UI testing"
    fi
    
    print_info "Building UI test target..."
    if xcodebuild build-for-testing \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_UI_TESTS" \
        -destination "$DESTINATION" \
        > build_ui.log 2>&1; then
        print_success "UI test build completed"
    else
        print_error "UI test build failed"
        if [ "$VERBOSE" = true ]; then
            cat build_ui.log
        fi
        exit 1
    fi
    
    print_info "Running UI tests..."
    if xcodebuild test-without-building \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_UI_TESTS" \
        -destination "$DESTINATION" \
        $TEST_OPTIONS \
        > ui_tests.log 2>&1; then
        print_success "UI tests passed"
        UI_TEST_COUNT=$(grep -c "Test Case.*passed" ui_tests.log || echo "0")
        TOTAL_TESTS=$((TOTAL_TESTS + UI_TEST_COUNT))
        PASSED_TESTS=$((PASSED_TESTS + UI_TEST_COUNT))
    else
        print_error "UI tests failed"
        UI_TEST_FAILURES=$(grep -c "Test Case.*failed" ui_tests.log || echo "0")
        UI_TEST_COUNT=$(grep -c "Test Case.*\(passed\|failed\)" ui_tests.log || echo "0")
        TOTAL_TESTS=$((TOTAL_TESTS + UI_TEST_COUNT))
        FAILED_TESTS=$((FAILED_TESTS + UI_TEST_FAILURES))
        PASSED_TESTS=$((PASSED_TESTS + UI_TEST_COUNT - UI_TEST_FAILURES))
        
        if [ "$VERBOSE" = true ]; then
            cat ui_tests.log
        else
            echo "Failed UI tests:"
            grep "Test Case.*failed" ui_tests.log || echo "No specific failures found"
        fi
    fi
    
    echo ""
fi

# Generate coverage report
if [ "$COVERAGE" = true ]; then
    print_header "GENERATING COVERAGE REPORT"
    
    # Find the latest result bundle
    RESULT_BUNDLE=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d | head -1)
    
    if [ -n "$RESULT_BUNDLE" ]; then
        print_info "Generating coverage report from: $RESULT_BUNDLE"
        
        # Extract coverage data
        if command -v xcparse >/dev/null 2>&1; then
            xcparse codecov "$RESULT_BUNDLE" coverage.xml
            print_success "Coverage report generated: coverage.xml"
        else
            print_warning "xcparse not found. Install with: brew install chargepoint/xcparse/xcparse"
            print_info "Coverage data available in: $RESULT_BUNDLE"
        fi
    else
        print_warning "No result bundle found for coverage report"
    fi
    
    echo ""
fi

# Test Summary
print_header "TEST SUMMARY"

echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
else
    echo -e "${GREEN}Failed: $FAILED_TESTS${NC}"
fi

# Calculate pass rate
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo -e "Pass Rate: $PASS_RATE%"
else
    echo -e "Pass Rate: N/A (no tests run)"
fi

echo ""

# Final status
if [ $FAILED_TESTS -eq 0 ]; then
    print_success "ALL TESTS PASSED! 🎉"
    
    if [ "$COVERAGE" = true ]; then
        print_info "Check coverage report for detailed analysis"
    fi
    
    print_info "Next steps:"
    echo "  • Review any performance test results"
    echo "  • Run manual testing checklist before release"
    echo "  • Consider running tests on multiple device types"
    
    exit 0
else
    print_error "SOME TESTS FAILED!"
    
    print_info "Troubleshooting steps:"
    echo "  • Check test logs for specific failure details"
    echo "  • Ensure proper device setup (Screen Time permissions, etc.)"
    echo "  • Run failed tests individually for debugging"
    echo "  • Review TESTING_GUIDE.md for common issues"
    
    exit 1
fi