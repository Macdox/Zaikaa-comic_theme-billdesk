document.addEventListener("DOMContentLoaded", function () {
    const form = document.querySelector(".signup-form");
    const emailInput = document.getElementById("email");
    const usernameInput = document.getElementById("username");
    const phoneInput = document.getElementById("phone");

    // Error message elements
    const emailError = document.createElement("p");
    const usernameError = document.createElement("p");
    const phoneError = document.createElement("p");

    [emailError, usernameError, phoneError].forEach(error => {
        error.style.color = "red";
        error.style.fontSize = "14px";
        error.style.marginTop = "5px";
        error.style.display = "none";
    });

    emailInput.parentNode.appendChild(emailError);
    usernameInput.parentNode.appendChild(usernameError);
    phoneInput.parentNode.appendChild(phoneError);

    // Email validation function
    function validateEmail() {
        const email = emailInput.value.trim();
        if (!email.endsWith("@sakec.ac.in")) {
            emailError.textContent = "Use @sakec.ac.in mail only";
            emailError.style.display = "block";
            return false;
        } else {
            emailError.style.display = "none";
            return true;
        }
    }

    // Username validation function (only letters and numbers allowed)
    function validateUsername() {
        const username = usernameInput.value.trim();
        const usernamePattern = /^[A-Za-z]+$/; // Only letters 
        if (!usernamePattern.test(username)) {
            usernameError.textContent = "Username can only contain letters (no special characters and numbers)";
            usernameError.style.display = "block";
            return false;
        } else {
            usernameError.style.display = "none";
            return true;
        }
    }

    // Phone number validation function (must be exactly 10 digits)
    function validatePhone() {
        const phone = phoneInput.value.trim();
        const phonePattern = /^[0-9]{10}$/; // Exactly 10 digits
        if (!phonePattern.test(phone)) {
            phoneError.textContent = "Phone number must be exactly 10 digits";
            phoneError.style.display = "block";
            return false;
        } else {
            phoneError.style.display = "none";
            return true;
        }
    }

    // Continuous validation on input
    emailInput.addEventListener("input", validateEmail);
    usernameInput.addEventListener("input", validateUsername);
    phoneInput.addEventListener("input", validatePhone);

    // Prevent form submission if any validation fails
    form.addEventListener("submit", function (event) {
        if (!validateEmail() || !validateUsername() || !validatePhone()) {
            event.preventDefault(); // Stop form submission
        }
    });
});


// Role switching logic
function setRole(role) {
    document.getElementById("role").value = role;
    const studentFields = document.getElementById("student-fields");
    const btnStudent = document.getElementById("btn-student");
    const btnStaff = document.getElementById("btn-staff");

    if (role === 'student') {
        studentFields.style.display = "block";
        btnStudent.classList.add("active");
        btnStaff.classList.remove("active");
        
        // Add required attribute for student fields
        document.getElementById("year").setAttribute("required", "true");
        document.getElementById("branch").setAttribute("required", "true");
    } else {
        studentFields.style.display = "none";
        btnStaff.classList.add("active");
        btnStudent.classList.remove("active");
        
        // Remove required attribute for staff fields
        document.getElementById("year").removeAttribute("required");
        document.getElementById("branch").removeAttribute("required");
    }
}

// Initial setup
document.addEventListener("DOMContentLoaded", function() {
    setRole('student'); // Default to student
});


function validateForm() {
    // Run existing validations
    if (!validatePassword()) return false;
    
    // Additional validations if triggered manually or via submit
    // Note: The input event listeners handle visual feedback, but we should double check here
    
    const role = document.getElementById("role").value;
    if (role === 'student') {
        const year = document.getElementById("year").value;
        const branch = document.getElementById("branch").value;
        
        if (!/^\d+$/.test(year)) {
            alert("Year must be a number.");
            return false;
        }
        if (!branch.trim()) {
            alert("Branch is required.");
            return false;
        }
    }
    
    return true;
}

function validatePassword() {
    var password = document.getElementById("password").value;
    var confirmPassword = document.getElementById("confirm-password").value;
    var regex = /^\d{6}$/;  // Ensures only 6-digit numbers

    if (!regex.test(password)) {
        alert("Password must be exactly 6 digits (numbers only).");
        return false;
    }

    if (password !== confirmPassword) {
        alert("Passwords do not match.");
        return false;
    }

    return true;  // Submit form if everything is valid
}