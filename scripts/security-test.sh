#!/bin/bash

# Local Security Testing Script
# This script helps developers test security tools locally before pushing code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Go tools if missing
install_go_tools() {
    print_status "Checking Go security tools..."
    
    if ! command_exists govulncheck; then
        print_status "Installing govulncheck..."
        go install golang.org/x/vuln/cmd/govulncheck@latest
    fi
    
    if ! command_exists gosec; then
        print_status "Installing gosec..."
        go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
    fi
    
    if ! command_exists staticcheck; then
        print_status "Installing staticcheck..."
        go install honnef.co/go/tools/cmd/staticcheck@latest
    fi
    
    print_success "Go security tools are ready"
}

# Function to run Go security scans
run_go_security_scan() {
    print_status "Running Go security scans..."
    
    # Create reports directory
    mkdir -p security-reports
    
    # Run govulncheck
    print_status "Running govulncheck..."
    if govulncheck ./... > security-reports/govulncheck.txt 2>&1; then
        print_success "govulncheck completed - no vulnerabilities found"
    else
        print_warning "govulncheck found vulnerabilities - check security-reports/govulncheck.txt"
    fi
    
    # Run gosec
    print_status "Running gosec..."
    if gosec -fmt=json -out=security-reports/gosec.json ./... > security-reports/gosec.txt 2>&1; then
        print_success "gosec completed - no security issues found"
    else
        print_warning "gosec found security issues - check security-reports/gosec.json"
    fi
    
    # Run staticcheck
    print_status "Running staticcheck..."
    if staticcheck ./... > security-reports/staticcheck.txt 2>&1; then
        print_success "staticcheck completed - no issues found"
    else
        print_warning "staticcheck found issues - check security-reports/staticcheck.txt"
    fi
}

# Function to run Docker security scan
run_docker_security_scan() {
    if [ ! -f "external/gateway/Dockerfile" ]; then
        print_warning "Dockerfile not found, skipping Docker security scan"
        return
    fi
    
    print_status "Running Docker security scan..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        return
    fi
    
    # Check if Syft is available
    if ! command_exists syft; then
        print_status "Installing Syft..."
        if command_exists brew; then
            brew install anchore/tap/syft
        else
            print_warning "Syft not found. Install it manually: https://github.com/anchore/syft#installation"
            return
        fi
    fi
    
    # Check if Grype is available
    if ! command_exists grype; then
        print_status "Installing Grype..."
        if command_exists brew; then
            brew install anchore/tap/grype
        else
            print_warning "Grype not found. Install it manually: https://github.com/anchore/grype#installation"
            return
        fi
    fi
    
    # Build test image
    print_status "Building test Docker image..."
    cd external/gateway
    docker build -t security-test:latest . > ../../security-reports/docker-build.log 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully"
        
        # Generate SBOM
        print_status "Generating SBOM with Syft..."
        syft security-test:latest -o spdx-json > ../../security-reports/sbom.json
        
        # Run vulnerability scan
        print_status "Running vulnerability scan with Grype..."
        grype security-test:latest -o json > ../../security-reports/vulnerabilities.json
        
        print_success "Docker security scan completed"
    else
        print_error "Failed to build Docker image - check security-reports/docker-build.log"
    fi
    
    cd ../..
}

# Function to run NPM security scan
run_npm_security_scan() {
    if [ ! -f "package.json" ] && [ -z "$(find . -name 'package.json' -type f)" ]; then
        print_status "No package.json files found, skipping NPM security scan"
        return
    fi
    
    print_status "Running NPM security scan..."
    
    # Find all package.json files
    find . -name "package.json" -type f | while read -r package_file; do
        dir=$(dirname "$package_file")
        print_status "Scanning dependencies in: $dir"
        
        cd "$dir"
        
        # Run npm audit
        if npm audit --audit-level=moderate --json > "../../security-reports/npm-audit-$(basename $dir).json" 2>/dev/null; then
            print_success "NPM audit completed for $dir"
        else
            print_warning "NPM audit found issues in $dir"
        fi
        
        cd - > /dev/null
    done
}

# Function to generate security summary
generate_security_summary() {
    print_status "Generating security summary..."
    
    cat > security-reports/security-summary.md << EOF
# Security Scan Summary

**Scan Date:** $(date)
**Repository:** $(basename "$PWD")

## Go Security Scan

EOF
    
    # Add Go scan results
    if [ -f "security-reports/govulncheck.txt" ]; then
        if grep -q "VULN:" security-reports/govulncheck.txt; then
            VULN_COUNT=$(grep -c "VULN:" security-reports/govulncheck.txt)
            echo "🔴 **Go Vulnerabilities:** $VULN_COUNT found" >> security-reports/security-summary.md
        else
            echo "✅ **Go Vulnerabilities:** None found" >> security-reports/security-summary.md
        fi
    fi
    
    if [ -f "security-reports/gosec.json" ]; then
        GOSEC_ISSUES=$(jq '.Issues | length' security-reports/gosec.json 2>/dev/null || echo "0")
        if [ "$GOSEC_ISSUES" -gt 0 ]; then
            echo "🟠 **Security Issues:** $GOSEC_ISSUES found" >> security-reports/security-summary.md
        else
            echo "✅ **Security Issues:** None found" >> security-reports/security-summary.md
        fi
    fi
    
    if [ -f "security-reports/staticcheck.txt" ]; then
        STATIC_ISSUES=$(grep -c ":" security-reports/staticcheck.txt || echo "0")
        if [ "$STATIC_ISSUES" -gt 0 ]; then
            echo "🟡 **Static Analysis:** $STATIC_ISSUES issues found" >> security-reports/security-summary.md
        else
            echo "✅ **Static Analysis:** No issues found" >> security-reports/security-summary.md
        fi
    fi
    
    # Add Docker scan results
    if [ -f "security-reports/vulnerabilities.json" ]; then
        echo "" >> security-reports/security-summary.md
        echo "## Docker Security Scan" >> security-reports/security-summary.md
        echo "" >> security-reports/security-summary.md
        
        VULN_COUNT=$(jq '.matches | length' security-reports/vulnerabilities.json 2>/dev/null || echo "0")
        if [ "$VULN_COUNT" -gt 0 ]; then
            echo "🔴 **Container Vulnerabilities:** $VULN_COUNT found" >> security-reports/security-summary.md
        else
            echo "✅ **Container Vulnerabilities:** None found" >> security-reports/security-summary.md
        fi
    fi
    
    # Add NPM scan results
    if [ -n "$(find security-reports -name 'npm-audit-*.json')" ]; then
        echo "" >> security-reports/security-summary.md
        echo "## NPM Security Scan" >> security-reports/security-summary.md
        echo "" >> security-reports/security-summary.md
        
        TOTAL_VULNS=0
        for audit_file in security-reports/npm-audit-*.json; do
            if [ -f "$audit_file" ]; then
                VULN_COUNT=$(jq '.vulnerabilities | length' "$audit_file" 2>/dev/null || echo "0")
                TOTAL_VULNS=$((TOTAL_VULNS + VULN_COUNT))
                DIR_NAME=$(basename "$audit_file" | sed 's/npm-audit-\(.*\)\.json/\1/')
                echo "📁 **$DIR_NAME:** $VULN_COUNT vulnerabilities" >> security-reports/security-summary.md
            fi
        done
        
        echo "" >> security-reports/security-summary.md
        echo "📊 **Total NPM Vulnerabilities:** $TOTAL_VULNS" >> security-reports/security-summary.md
    fi
    
    echo "" >> security-reports/security-summary.md
    echo "---" >> security-reports/security-summary.md
    echo "*Generated by local security testing script*" >> security-reports/security-summary.md
    
    print_success "Security summary generated: security-reports/security-summary.md"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -g, --go-only           Run only Go security scans"
    echo "  -d, --docker-only       Run only Docker security scans"
    echo "  -n, --npm-only          Run only NPM security scans"
    echo "  -a, --all               Run all security scans (default)"
    echo "  -s, --summary           Generate security summary only"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run all scans"
    echo "  $0 --go-only            # Run only Go security scans"
    echo "  $0 --docker-only        # Run only Docker security scans"
    echo "  $0 --summary            # Generate summary from existing reports"
}

# Main execution
main() {
    local run_go=true
    local run_docker=true
    local run_npm=true
    local generate_summary=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -g|--go-only)
                run_docker=false
                run_npm=false
                shift
                ;;
            -d|--docker-only)
                run_go=false
                run_npm=false
                shift
                ;;
            -n|--npm-only)
                run_go=false
                run_docker=false
                shift
                ;;
            -a|--all)
                run_go=true
                run_docker=true
                run_npm=true
                shift
                ;;
            -s|--summary)
                run_go=false
                run_docker=false
                run_npm=false
                generate_summary=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "Starting local security testing..."
    
    # Create reports directory
    mkdir -p security-reports
    
    # Run selected scans
    if [ "$run_go" = true ]; then
        install_go_tools
        run_go_security_scan
    fi
    
    if [ "$run_docker" = true ]; then
        run_docker_security_scan
    fi
    
    if [ "$run_npm" = true ]; then
        run_npm_security_scan
    fi
    
    # Generate summary
    if [ "$generate_summary" = true ]; then
        generate_security_summary
    fi
    
    print_success "Security testing completed!"
    print_status "Check security-reports/ directory for detailed results"
    print_status "Review security-reports/security-summary.md for overview"
}

# Run main function with all arguments
main "$@"
