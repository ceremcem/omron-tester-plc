export io-list = 
    'my1':
        # Digital outputs start from C100 (see Omron Memory Documentation)
        'c100:2': "test_out_2":
            text:
                0: "Off"
                1: "On"
        'c100:3': "test_out_3":
            text:
                0: "Stopped"
                1: "Running"

        'd102': 'test_register_1':
            text:
                0: "Idle"
                1: "Normal"
                100: "Test Mode"

        # Digital inputs start from C0
        'c0:0': "test_input_0":
            text:
                0: "Yok"
                1: "Var"

        # Laser control system Input/Outputs
        'd0': 'conveyor_speed':
            description: "Konveyör hızı"
            unit: 1/10
            type: "int"
            format: '#.# m/dk'
            max: 300
            graph: 
                size: 200points
        'd1': 'hole_diameter':
            description: "Delik çapı"
            unit: (1/100 * 2)
            format: '#.# mm'
        'd2': "calibration_length":
            description: "Kalibrasyon uzunluğu"
            unit: 1/100
            format: "#.## mm"
        'd3': "operating_mode":
            description: "Çalışma modu"
            text:
                0: "Boşta"
                1: "Atış"
                100: "Test Square"
        'd4': "laser_trace_duration":
            description: "Atış süresi"
            unit: 1/100
            format: "#.## ms"
            max: 10
        'd5': 'laser_power':
            description: "Lazer gücü"
            format: '% #'
        'd16': 'control_card_heartbeat':
            log: when: (is 0)
        'd17': 'rejected_count'   
        'd19': 'current_temperature':
            description: "Galvo sıcaklığı"
            unit: 1/10       
            format: "#.# °C"
            disregard: 0.5_C
            graph: 
                size: 200points
        'd21': "plc_heartbeat":
            log: no 
        'd28': "low_severity_error"
        'd29': "high_severity_error"
        'd28:1': 'calibration_length_error'

        # Application's debug registers
        'd100': 'total_modbus_change_count':
            log: no 
        'd101': 'force_update_counter'
