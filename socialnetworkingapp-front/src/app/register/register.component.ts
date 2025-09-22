import { Component, OnInit } from '@angular/core';
import { FormGroup, FormControl, FormBuilder, Validators, FormArray } from "@angular/forms";
import { AccountService } from "../account/account.service";
import { HttpEventType, HttpResponse } from "@angular/common/http";
import { Account } from "../account/account";
import { Router } from '@angular/router';
import { UploadFileService } from "../upload-files/upload-files.service";
import { BioService } from "../bio/bio.service";
import { AuthenticationService } from '../authentication';
import { TagsService } from "../tags/tags.service";
import {Tag} from '../tags/Tag'

@Component({
    selector: 'app-register',
    templateUrl: './register.component.html',
    styleUrls: ['./register.component.css']
})
export class RegisterComponent implements OnInit {

  registerForm!: FormGroup;
  correctCredentials = true;
  errorMessage: string | null = null; // holds dynamic backend error messages
  selectedFiles: FileList | null = null;
  currentFile: File | null = null;
  progress = 0;
  message = '';
  TagsArray : Tag[] = [];


  private account!: Account;

    constructor(
        private accountService: AccountService,
        private authService: AuthenticationService,
        public router: Router,
        private uploadService: UploadFileService,
        private bioService: BioService,
        private fb: FormBuilder,
        private tagsService: TagsService,
        private authenticationService : AuthenticationService

    ) { }

    ngOnInit(): void {
        if (this.authService.isLoggedIn()) {
            this.router.navigate(['/home']);
        }

        this.registerForm = this.fb.group({
            email: new FormControl('', [Validators.required, Validators.pattern("^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,4}$")]),
            password: new FormControl('', [Validators.required, Validators.minLength(8), Validators.maxLength(16)]),
            conf_password: new FormControl('', [Validators.required, Validators.minLength(8), Validators.maxLength(16)]),
            firstName: new FormControl('', [Validators.required, Validators.maxLength(20), Validators.pattern('[a-zA-Z ]*')]),
            lastName: new FormControl('', [Validators.required, Validators.maxLength(20), Validators.pattern('[a-zA-Z ]*')]),
            phone: new FormControl('', [Validators.required, Validators.pattern('[0-9]*'), Validators.maxLength(15)]),
            // Interests are required (min 2) only if we actually have tags to show; validator swapped dynamically after load.
            interests: this.fb.array([])
        },
            { validator: this.checkPasswords }
        );

        this.loadTags();

    }
    private loadTags(){
      this.tagsService.getAllTags().subscribe(
        (response: Tag[]) => {
          this.TagsArray = response || [];
          if(this.TagsArray.length === 0){
            // Fallback default tags (mirrors seed data) so user can still choose.
            this.TagsArray = [ 'TECHNOLOGY','BUSINESS','MACHINE LEARNING','SOFTWARE' ].map(t=> new Tag(t));
          }
          this.applyInterestValidators();
        },
        (err) => {
          console.error('[register] Failed to load tags', err);
          // Provide fallback defaults instead of blocking registration.
          this.TagsArray = [ 'TECHNOLOGY','BUSINESS','MACHINE LEARNING','SOFTWARE' ].map(t=> new Tag(t));
          this.applyInterestValidators();
        }
      );
    }

    private applyInterestValidators(){
      const interestsCtl = this.registerForm.get('interests');
      if(!interestsCtl){ return; }
      if(this.TagsArray.length > 0){
        interestsCtl.setValidators([Validators.required, Validators.minLength(2)]);
      } else {
        // No tags available, make interests optional so user can sign up.
        interestsCtl.clearValidators();
      }
      interestsCtl.updateValueAndValidity();
    }

    onCbChange(e : any) {
        const interests : FormArray = this.registerForm.get('interests') as FormArray;
        if (e.target.checked) {
           interests.push(new FormControl(e.target.value));
        } else {
            let i: number = 0;
            interests.controls.forEach((item: any) => {
                if (item.value == e.target.value) {
                    interests.removeAt(i);
                    return;
                }
                i++;
            });
        }
    }

    selectFile(event: any) {
        this.selectedFiles = event.target.files;
    }

    checkPasswords(group: FormGroup) {
        const password = group.controls.password.value;
        const confirm_password = group.controls.conf_password.value;
        return password === confirm_password ? null : { notSame: true };
    }

    upload() {
        this.progress = 0;
    if(!this.selectedFiles || this.selectedFiles.length === 0){
      return;
    }
    const first = this.selectedFiles.item(0);
    if(!first){ return; }
    this.currentFile = first;
    this.uploadService.uploadUser(this.currentFile, this.authenticationService.getJWT()).subscribe(
            event => {
        if (event.type === HttpEventType.UploadProgress && event.total) {
          this.progress = Math.round(100 * event.loaded / event.total);
                } else if (event instanceof HttpResponse) {
                    this.message = event.body.message;
                }
                this.onClickModal('uploadSuccessful');
            },
            err => {
                this.progress = 0;
                this.message = 'Could not upload the file!';
        this.currentFile = null;
            });
    this.selectedFiles = null;
    }

  public onRegister(registerForm: FormGroup): void {
    // Build payload explicitly to match backend RegistrationRequest contract
    const raw = registerForm.value;
    const interests = (raw.interests || []).map((t: string) => ({ tag: t }));
    const payload = {
      firstName: raw.firstName,
      lastName: raw.lastName,
      email: raw.email,
      password: raw.password,
      phone: raw.phone,
      interests: interests
    };

    this.errorMessage = null;
    this.correctCredentials = true;

    this.accountService.registerAccount(payload).subscribe(
      () => {
        this.authService.logIn({ 'username': payload.email, 'password': payload.password }).subscribe(
          () => {
            this.onClickModal('addPhoto');
          },
          (loginError) => {
            console.error('[register] auto-login failed after registration', loginError);
            this.errorMessage = 'Account created but automatic login failed. Please login manually.';
          }
        );
      },
      (error: any) => {
        console.error('[register] registration failed', error);
        this.correctCredentials = false; // keep legacy flag (unused by new message block but might be referenced elsewhere)
        // Distinguish common failure modes
        if (error.status === 409) {
          this.errorMessage = 'A user with the same email or phone already exists.';
        } else if (error.status === 400) {
          this.errorMessage = 'Invalid registration data. Please review your inputs.';
        } else if (error.status === 0) {
          this.errorMessage = 'Cannot reach server. Check your network connection.';
        } else {
          this.errorMessage = 'Registration failed with error ' + (error.error?.message || error.statusText || error.status);
        }
      }
    );

  }

    public onClickModal(mode: string): void {

        const container = document.getElementById('main-container');

        const button = document.createElement('button');
        button.type = 'button';
        button.style.display = 'none';
        button.setAttribute('data-toggle', 'modal');

        if (mode === 'addPhoto') {
            button.setAttribute('data-target', '#addPhoto');
        }
        if (mode === 'uploadSuccessful') {
          button.setAttribute('data-target', '#uploadSuccessful');
        }
        if (container != null) {
            container.appendChild(button);
            button.click();
        }

    }

  public goToHomePage() {
    window.location.reload();
    this.router.navigateByUrl('/home');
  }
}
