from flask import Flask, request, jsonify
import subprocess
import os
import uuid
import threading

app = Flask(__name__)

service_bindings = {}

# Service Broker Catalog
CATALOG = {
    "services": [
        {
            "id": "java-optimizer-id",
            "name": "java-optimizer",
            "description": "CF Java-Optimizer-Broker service",
            "bindable": True,
            "plans": [
                {
                    "id": "native-compile-plan-id",
                    "name": "native-compile",
                    "description": "GraalVM Native Compliation",
                }
            ]
        }
    ]
}


# CATALOG / MARKETPLACE
@app.route('/v2/catalog', methods=['GET'])
def catalog():
    return jsonify(CATALOG)


# CREATE SERVICE
@app.route('/v2/service_instances/<instance_id>', methods=['PUT'])
def create_service_instance(instance_id):
    data = request.get_json()
    service_id = data.get("service_id")
    plan_id = data.get("plan_id")

    if service_id != "java-optimizer-id" or plan_id != "native-compile-plan-id":
        return jsonify({"error": "Service or plan not supported"}), 400
    
    app_name = f"java-optimizer-broker-app-{instance_id}"

    def async_provision(): 
        try:
            command = ["./create-service.sh"]
            print("calling script: " , command)
            result = subprocess.run(command, text=True, capture_output=True)
            print("Script Output(stdout):", result.stdout)
            print("Script Output:(stderr)", result.stderr)
            print("SCRIPT CALLED")
        except subprocess.CalledProcessError as e:
            print("Error running script:", e)
            print("Script Error Output:", e.stderr)

    threading.Thread(target=async_provision).start() 
    return jsonify({
        "operation": f"provision-{instance_id}"
    }), 202


# UNBIND-SERVICE
@app.route('/v2/service_instances/<instance_id>/service_bindings/<binding_id>', methods=['DELETE'])
def unbind_service(instance_id, binding_id):
    """
    Handles the unbind-service request.
    Removes the binding between a service instance and an application.
    """
    # Parse required query parameters (as per the OSB spec)
    service_id = request.args.get('service_id')
    plan_id = request.args.get('plan_id')

    # Validate input
    if not service_id or not plan_id:
        return jsonify({"error": "service_id and plan_id are required"}), 400

    # Check if the binding exists
    binding_key = (instance_id, binding_id)
    if binding_key not in service_bindings:
        # Per OSB spec, unbind should be idempotent
        return jsonify({}), 200

    # Remove the binding
    del service_bindings[binding_key]
    print(f"Unbound service binding: {binding_key}")

    # Respond with success
    return jsonify({}), 200
                   
# DELETE-SERVICE
@app.route('/v2/service_instances/<instance_id>', methods=['DELETE'])
def delete_service_instance(instance_id):
    app_name = f"java-optimizer-broker-app-{instance_id}"

    try:
        subprocess.run(["./delete-service.sh"], check=True)
        return jsonify({}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Failed to delete: {e}"}), 500
    

@app.route('/v2/service_instances/<instance_id>/last_operation', methods=['GET'])
def last_operation(instance_id):
    operation = request.args.get("operation")

    # For simplicity, assume the operation is completed
    # In a real-world scenario, you would check the actual status of the provisioning task
    if operation.startswith("provision-"):
        return jsonify({"state": "succeeded"}), 200
    else:
        return jsonify({"state": "failed"}), 500
    
    
# BIND-SERVICE
@app.route('/v2/service_instances/<instance_id>/service_bindings/<binding_id>', methods=['PUT'])
def bind_service(instance_id, binding_id):
    data = request.get_json()
    service_id = data.get("service_id")
    plan_id = data.get("plan_id")
    parameters = data.get("parameters", {})
    app_guid = data.get("bind_resource", {}).get("app_guid")
    
    # Validate service and plan
    if service_id != "java-optimizer-id":
        return jsonify({"error": "Service not supported"}), 400
    if plan_id not in ["native-compile-plan-id", "foo-plan-id"]:
        return jsonify({"error": "Plan not supported"}), 400
    
    # Store the binding in memory
    service_bindings[(instance_id, binding_id)] = {
        "service_id": service_id,
        "plan_id": plan_id,
        "parameters": parameters,
    }


    def async_bind(): 
        try:
            print("inside async_bind")
            args = [f"--{key}={value}" for key, value in data.items()]
            print("args",args)
            command = ["./bind-service.sh"]
            print("calling script: " , command)
            result = subprocess.run(command + args, text=True, capture_output=True)
            print("Script Output(stdout):", result.stdout)
            print("Script Output:(stderr)", result.stderr)
            print("SCRIPT CALLED")
        except subprocess.CalledProcessError as e:
            print("Error running script:", e)
            print("Script Error Output:", e.stderr)

    threading.Thread(target=async_bind).start() 

    # Example: Generate credentials (this could involve retrieving or creating API keys, DB creds, etc.)
    credentials = {
        "username": f"user",
        "password": "password",
        "url": f"https://app-replicator-{instance_id}.homelab2.fynesy.com"
    }

    # Optional: Perform binding logic, like updating the Groovy app configuration

    # Return binding response
    return jsonify({
        "credentials": credentials
    }), 201







if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
