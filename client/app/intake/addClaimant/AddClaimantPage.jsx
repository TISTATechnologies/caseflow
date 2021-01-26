import React from 'react';
import { useHistory } from 'react-router';
import { FormProvider, Controller } from 'react-hook-form';
import styled from 'styled-components';

import { IntakeLayout } from '../components/IntakeLayout';
import SearchableDropdown from 'app/components/SearchableDropdown';
import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';
import AddressForm from 'app/components/AddressForm';
import { AddClaimantButtons } from './AddClaimantButtons';
import * as Constants from '../constants';

import { useAddClaimantForm } from './utils';
import { ADD_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';

const relationshipOpts = [
  { value: 'attorney', label: 'Attorney (previously or currently)' },
  { value: 'child', label: 'Child' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'other', label: 'Other' },
];

const partyTypeOpts = [
  { displayText: 'Organization', value: 'organization' },
  { displayText: 'Individual', value: 'individual' }
];

export const AddClaimantPage = () => {
  const { goBack } = useHistory();
  const methods = useAddClaimantForm();
  const {
    control,
    register,
    watch,
    formState: { isValid },
    handleSubmit,
  } = methods;
  const onSubmit = (formData) => {
    // Update this to...
    // Add claimant info to Redux
    // Probably handle submission of both claimant and remaining intake info (from Review step)
    return formData;
  };
  const handleBack = () => goBack();

  const watchPartyType = watch('partyType');
  const watchRelationship = watch('relationship')?.value;

  const showIndividualNameFields = watchPartyType === 'individual' || ['spouse', 'child'].includes(watchRelationship);
  const showPartyType = ['other', 'attorney'].includes(watchRelationship);
  const showAdditionalFields = watchPartyType || ['spouse', 'child'].includes(watchRelationship);

  return (
    <FormProvider {...methods}>
      <IntakeLayout
        buttons={
          <AddClaimantButtons
            onBack={handleBack}
            onSubmit={handleSubmit(onSubmit)}
            isValid={isValid}
          />
        }
      >
        <h1>Add Claimant</h1>
        <p>{ADD_CLAIMANT_PAGE_DESCRIPTION}</p>

        <form onSubmit={handleSubmit(onSubmit)}>
          <Controller
            control={control}
            name="relationship"
            label="Relationship to the Veteran"
            options={relationshipOpts}
            strongLabel
            as={SearchableDropdown}
          />
          <br />
          { showPartyType &&
            <RadioField
              name="partyType"
              label="Is the claimant an organization or individual?"
              inputRef={register}
              strongLabel
              vertical
              options={partyTypeOpts}
            />
          }
          <br />
          { showIndividualNameFields &&
            <>
              <FieldDiv>
                <TextField
                  name="firstName"
                  label="First name"
                  inputRef={register}
                  strongLabel
                />
              </FieldDiv>
              <FieldDiv>
                <TextField
                  name="middleName"
                  label="Middle name/initial"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </FieldDiv>
              <FieldDiv>
                <TextField
                  name="lastName"
                  label="Last name"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </FieldDiv>
              <Suffix>
                <TextField
                  name="suffix"
                  label="Suffix"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </Suffix>
            </>
          }
          { watchPartyType === 'organization' &&
            <TextField
              name="organization"
              label="Organization name"
              inputRef={register}
              strongLabel
            />
          }
          { showAdditionalFields &&
            <>
              <AddressForm {...methods} />
              <FieldDiv>
                <TextField
                  name="email"
                  label="Claimant email"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </FieldDiv>
              <PhoneNumber>
                <TextField
                  name="phoneNumber"
                  label="Phone number"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </PhoneNumber>
              <RadioField
                options={Constants.BOOLEAN_RADIO_OPTIONS}
                vertical
                inputRef={register}
                label="Do you have a VA Form 21-22 for this claimant?"
                name="vaForm"
                strongLabel
              />
            </>
          }
        </form>
      </IntakeLayout>
    </FormProvider>
  );
};

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

const Suffix = styled.div`
  max-width: 8em;
`;

const PhoneNumber = styled.div`
  width: 240px;
  margin-bottom: 2em;
`;